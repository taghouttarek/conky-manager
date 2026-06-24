#!/usr/bin/env python3
import urllib.request
import json
import argparse
import os
import time

CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache", "conky-vulns")
os.makedirs(CACHE_DIR, exist_ok=True)

INFRA_VENDORS = [
    "kubernetes", "docker", "keycloak", "postgresql", "postgres",
    "helm", "argo", "argocd", "nginx", "redis", "etcd", "vault",
    "hashicorp", "jenkins", "gitlab", "grafana", "prometheus",
    "elasticsearch", "kibana", "rabbitmq", "kafka", "consul",
    "istio", "envoy", "traefik", "harbor", "sonarqube",
    "minio", "ceph", "longhorn", "rancher", "openshift",
    "spring", "tomcat", "apache", "openssl", "golang",
    "nodejs", "python", "java", "php", "linux", "kernel",
]


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


def fetch_infra_vulns(count=5):
    cache_key = f"infra_{count}"
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
    for v in data.get("vulnerabilities", []):
        vendor = v.get("vendorProject", "").lower()
        product = v.get("product", "").lower()
        combined = vendor + " " + product

        for target in INFRA_VENDORS:
            if target in combined:
                vulns.append({
                    "id": v.get("cveID", "?"),
                    "vendor": v.get("vendorProject", "?"),
                    "product": v.get("product", "?"),
                    "date": v.get("dateAdded", "?"),
                })
                break

    vulns.sort(key=lambda x: x["date"], reverse=True)
    result = vulns[:count]
    cache_set(cache_key, json.dumps(result))
    return result


parser = argparse.ArgumentParser(description="Infra CVE fetcher")
parser.add_argument("--get_list", action="store_true")
parser.add_argument("--count", type=int, default=5)
args = parser.parse_args()

if args.get_list:
    vulns = fetch_infra_vulns(args.count)
    for v in vulns:
        print(f"{v['id']}|{v['vendor']}|{v['product']}|{v['date']}")
