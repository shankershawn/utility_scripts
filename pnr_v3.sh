#!/bin/sh

# Rigorous error handling
set -eu

# --- Configuration ---
# Redis configuration
REDIS_HOST="144.24.128.195"
REDIS_PORT="8082"
REDIS_PNR_LIST_KEY="pnr_list"

# API endpoint and credentials
API_BASE_URL="https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb"
API_KEY="ct-web!2$"
DEVICE_ID="a1b2355f-d43b-47f1-8b65-a95c09bc4887"

# Email recipients
EMAIL_RECIPIENTS="shankarsan.ganai@icloud.com,nairitamganai@gmail.com,tkganaintpc@gmail.com"

# Notification service URL
NOTIFICATION_URL="http://129.154.37.114:5001/v1/message/battery_level"

# Temporary file for the API response
RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

# --- Main Logic ---
main() {
    # Check for required commands
    if ! command -v redis-cli >/dev/null 2>&1; then
        echo "Error: The 'redis-cli' command is not installed." >&2
        exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: The 'jq' command is not installed." >&2
        exit 1
    fi

    pnr_list=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SMEMBERS "$REDIS_PNR_LIST_KEY")

    if [ -z "$pnr_list" ]; then
        echo "No PNRs found in Redis set '$REDIS_PNR_LIST_KEY'. Exiting."
        exit 0
    fi

    for pnr in $pnr_list; do
        echo "Processing PNR: $pnr"
        process_pnr "$pnr"
    done
}

# Fetches PNR data from the API
fetch_pnr_data() {
    pnr="$1"
    curl --fail --silent --location \
        -H "Accept: */*" \
        -H "Accept-Language: en-IN,en-GB;q=0.9,en-US;q=0.8,en;q=0.7" \
        -H "ApiKey: $API_KEY" \
        -H "CT-Token;" \
        -H "CT-Userkey;" \
        -H "ClientId: ct-web" \
        -H "Connection: keep-alive" \
        -H "Content-Type: application/json" \
        -H "DeviceId: $DEVICE_ID" \
        -H "Origin: https://www.confirmtkt.com" \
        -H "Referer: https://www.confirmtkt.com/" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: same-site" \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36' \
        --data-raw '{"proPlanName":"CP7","emailId":"","tempToken":""}' \
        "$API_BASE_URL/$pnr?querysource=ct-web&locale=en&getHighChanceText=true&livePnr=false" > "$RESPONSE_FILE"
}

# Processes a single PNR
process_pnr() {
    pnr="$1"
    redis_key="pnr_data_$pnr"

    if ! fetch_pnr_data "$pnr"; then
        echo "Error: Failed to fetch data for PNR $pnr" >&2
        return
    fi

    pnr_response=$(jq -r '.data.pnrResponse' "$RESPONSE_FILE")

    if [ -z "$pnr_response" ] || [ "$pnr_response" = "null" ]; then
        echo "No valid PNR response for $pnr"
        return
    fi

    train_no=$(echo "$pnr_response" | jq -r '.trainNo')

    if [ -n "$train_no" ]; then
        current_status_json=$(echo "$pnr_response" | jq -c '[.passengerStatus[] | {Passenger: .number, BookingStatus: .bookingStatus, CurrentStatus: .currentStatus} | with_entries(select(.value != null))]')

        previous_status_json=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" GET "$redis_key" || echo "")

        should_send_mail="false"
        email_reply_prefix=""

        if [ -n "$previous_status_json" ]; then
            email_reply_prefix="Re:"
            if [ "$current_status_json" != "$previous_status_json" ]; then
                should_send_mail="true"
            fi
        else
            should_send_mail="true"
        fi

        if [ "$should_send_mail" = "true" ]; then
            send_email_notification "$pnr" "$pnr_response" "$current_status_json" "$email_reply_prefix"
            send_pulse_notification
            redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SET "$redis_key" "$current_status_json"
        fi
    fi
}

# Generates an HTML table from JSON data
generate_html_table() {
    json_data="$1"
    echo "$json_data" | jq -r '
      "<table border=\"1\" cellpadding=\"8\" cellspacing=\"0\" style=\"border-collapse: collapse; font-family: sans-serif; width: auto;\">" +
      "<thead>" +
        "<tr style=\"background-color: #f2f2f2; text-align: left;\">" +
          "<th>Passenger</th>" +
          "<th>Booking Status</th>" +
          "<th>Current Status</th>" +
        "</tr>" +
      "</thead>" +
      "<tbody>" +
      (
        map(
          "<tr>" +
            "<td>\(.Passenger)</td>" +
            "<td>\(.BookingStatus)</td>" +
            "<td>\(.CurrentStatus)</td>" +
          "</tr>"
        ) | join("")
      ) +
      "</tbody>" +
      "</table>"
    '
}

# Sends an email notification
send_email_notification() {
    pnr="$1"
    pnr_response="$2"
    status_json="$3"
    reply_prefix="$4"

    train_name=$(echo "$pnr_response" | jq '.trainName')
    doj=$(echo "$pnr_response" | jq '.doj')
    boarding_point=$(echo "$pnr_response" | jq '.boardingPoint')
    reservation_upto=$(echo "$pnr_response" | jq '.reservationUpto')
    class=$(echo "$pnr_response" | jq '.class')

    subject="$reply_prefix PNR $pnr - $train_no - $train_name - $doj - $boarding_point to $reservation_upto - $class"

    html_body=$(generate_html_table "$status_json")

    (
        echo "To: $EMAIL_RECIPIENTS"
        echo "Subject: $subject"
        echo "Content-Type: text/html"
        echo
        echo "$html_body"
    ) | sendmail -t

    echo "Email sent for PNR $pnr"
}

# Sends a pulse notification
send_pulse_notification() {
    curl --fail --silent --location --request POST "$NOTIFICATION_URL" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "pulseCount": 1,
            "pulseMillis": 100,
            "intervalMillis": 0
        }'
    echo "Pulse notification sent"
}

# --- Script Entry Point ---
main
