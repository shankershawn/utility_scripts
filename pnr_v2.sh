#!/bin/sh

# Rigorous error handling
set -eu

# --- Configuration ---
# File containing the list of PNRs to check
PNR_FILE="pnrlist.txt"

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
    if [ ! -f "$PNR_FILE" ]; then
        echo "Error: PNR file not found at '$PNR_FILE'" >&2
        exit 1
    fi

    while read -r pnr || [ -n "$pnr" ]; do
        echo "Processing PNR: $pnr"
        process_pnr "$pnr"
    done < "$PNR_FILE"
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
        current_status_file=$(mktemp)
        trap 'rm -f "$current_status_file"' EXIT

        echo "$pnr_response" | jq -r '[.passengerStatus[] | {Passenger: .number, BookingStatus: .bookingStatus, CurrentStatus: .currentStatus} | with_entries(select(.value != null))]' > "$current_status_file"

        previous_status_file="pnr_data_$pnr.txt"
        should_send_mail="false"
        email_reply_prefix=""

        if [ -f "$previous_status_file" ]; then
            email_reply_prefix="Re:"
            if ! diff -q "$current_status_file" "$previous_status_file" >/dev/null; then
                should_send_mail="true"
            fi
        else
            should_send_mail="true"
        fi

        if [ "$should_send_mail" = "true" ]; then
            send_email_notification "$pnr" "$pnr_response" "$current_status_file" "$email_reply_prefix"
            send_pulse_notification
        fi

        mv "$current_status_file" "$previous_status_file"
    fi
}

# Sends an email notification
send_email_notification() {
    pnr="$1"
    pnr_response="$2"
    status_file="$3"
    reply_prefix="$4"

    train_name=$(echo "$pnr_response" | jq '.trainName')
    doj=$(echo "$pnr_response" | jq '.doj')
    boarding_point=$(echo "$pnr_response" | jq '.boardingPoint')
    reservation_upto=$(echo "$pnr_response" | jq '.reservationUpto')
    class=$(echo "$pnr_response" | jq '.class')

    subject="$reply_prefix PNR $pnr - $train_no - $train_name - $doj - $boarding_point to $reservation_upto - $class"

    cat "$status_file" | mail -s "$subject" "$EMAIL_RECIPIENTS"
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
