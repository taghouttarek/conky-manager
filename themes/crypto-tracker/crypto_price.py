#!/usr/bin/env python3
import urllib.request
import json
import argparse
import os
import time

CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache", "conky-crypto")
os.makedirs(CACHE_DIR, exist_ok=True)


def cache_get(key, max_age=60):
    path = os.path.join(CACHE_DIR, key)
    if os.path.exists(path):
        age = time.time() - os.path.getmtime(path)
        if age < max_age:
            with open(path) as f:
                return f.read()
    return None


def cache_set(key, value):
    path = os.path.join(CACHE_DIR, key)
    with open(path, "w") as f:
        f.write(value)


def api_get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode())


def fetch_price(coin_id, currency):
    cache_key = f"price_{coin_id}_{currency}"
    cached = cache_get(cache_key, 30)
    if cached:
        return json.loads(cached)
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_id}&vs_currencies={currency}&include_24hr_change=true&include_market_cap=true"
    data = api_get(url)
    result = data.get(coin_id, {})
    cache_set(cache_key, json.dumps(result))
    return result


def fetch_chart(coin_id, currency, days):
    cache_key = f"chart_{coin_id}_{currency}_{days}"
    cached = cache_get(cache_key, 120)
    if cached:
        return cached
    url = f"https://api.coingecko.com/api/v3/coins/{coin_id}/market_chart?vs_currency={currency}&days={days}"
    data = api_get(url)
    prices = data.get("prices", [])
    result = ",".join(f"{p[1]:.2f}" for p in prices)
    cache_set(cache_key, result)
    return result


def format_number(n):
    if n is None:
        return "N/A"
    if n >= 1_000_000_000:
        return f"{n/1_000_000_000:.2f}B"
    if n >= 1_000_000:
        return f"{n/1_000_000:.2f}M"
    if n >= 1_000:
        return f"{n/1_000:.2f}K"
    return f"{n:.2f}"


parser = argparse.ArgumentParser(description="Crypto price fetcher")
parser.add_argument("--coin", default="solana")
parser.add_argument("--currency", default="usd")
parser.add_argument("--days", default="7")
parser.add_argument("--get_price", action="store_true")
parser.add_argument("--get_change", action="store_true")
parser.add_argument("--get_market_cap", action="store_true")
parser.add_argument("--get_symbol", action="store_true")
parser.add_argument("--get_chart", action="store_true")
parser.add_argument("--get_all", action="store_true")
args = parser.parse_args()

if args.get_chart:
    print(fetch_chart(args.coin, args.currency, args.days))
elif args.get_symbol:
    print(args.coin.upper().replace(" ", ""))
else:
    data = fetch_price(args.coin, args.currency)
    if args.get_all:
        price = data.get(args.currency, 0)
        change = data.get(f"{args.currency}_24h_change", 0)
        mcap = data.get(f"{args.currency}_market_cap", 0)
        print(f"PRICE:{price:.2f}")
        print(f"CHANGE:{change:.2f}")
        print(f"MCAP:{format_number(mcap)}")
    elif args.get_price:
        print(f"{data.get(args.currency, 0):.2f}")
    elif args.get_change:
        print(f"{data.get(f'{args.currency}_24h_change', 0):.2f}")
    elif args.get_market_cap:
        print(format_number(data.get(f"{args.currency}_market_cap", 0)))
