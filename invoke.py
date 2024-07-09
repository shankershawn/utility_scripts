import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor

import requests
from tqdm import tqdm

if len(sys.argv) < 5:
    print("Insufficient arguments. Usage invoke.py <user> <x-user-info> <id> <iterations>")
    exit(0)

url = "https://api.hushup.app/user/" + sys.argv[1] + "/message"

headers = {
    'sec-ch-ua': '"Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"',
    'sec-ch-ua-mobile': '?0',
    'x-user-info': sys.argv[2],
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebK' +
                  'it/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/plain, */*',
    'Referer': 'https://hushup.app/',
    'sec-ch-ua-platform': '"macOS"'
}


def fireApi():
    payload = json.dumps({
        "message": str(round(time.time() * 10000000)),
        "id": sys.argv[3],
        "username": sys.argv[1],
        "version": 2
    })
    response = requests.request("POST", url, headers=headers, data=payload)


print("Start time is " + str(round((time.time()))))

futures = []
count = 0

with tqdm(total=int(sys.argv[4])) as pbar:
    with ThreadPoolExecutor(max_workers=200) as executor:
        for x in range(int(sys.argv[4])):
            future = executor.submit(fireApi)
            future.add_done_callback(lambda tempFuture: pbar.update(1))

print("End time is " + str(round((time.time()))))
print(count)
