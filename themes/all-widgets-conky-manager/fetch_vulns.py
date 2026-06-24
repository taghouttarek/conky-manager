#!/usr/bin/env python3
import urllib.request
import json
import argparse
import os
import time

CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache", "conky-vulns")
os.makedirs(CACHE_DIR, exist_ok=True)


def cache_get(key, max_age=300):
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


def fetch_kev(count=5):
    cache_key = f"kev_{count}"
    cached = cache_get(cache_key, 600)
    if cached:
        return json.loads(cached)

    url = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
    except Exception:
        return []

    vulns = []
    for v in data.get("vulnerabilities", [])[:count]:
        vulns.append({
            "id": v.get("cveID", "?"),
            "vendor": v.get("vendorProject", "?"),
            "product": v.get("product", "?"),
            "date": v.get("dateAdded", "?"),
        })

    cache_set(cache_key, json.dumps(vulns))
    return vulns


parser = argparse.ArgumentParser(description="KEV fetcher")
parser.add_argument("--get_list", action="store_true")
parser.add_argument("--count", type=int, default=5)
args = parser.parse_args()

if args.get_list:
    vulns = fetch_kev(args.count)
    for v in vulns:
        print(f"{v['id']}|{v['vendor']}|{v['product']}|{v['date']}")
