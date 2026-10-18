#!/usr/bin/env python3
"""
Poll the Apple Certified Refurbished store for target Mac Studio configs and
record price + stock, using each page's JSON-LD Product/Offer data (authoritative
per-product price and availability), not the JS configurator.

Outputs:
  watchlist/latest.json   machine-readable snapshot
  watchlist/README.md     human-readable table

With --commit, commits (and pushes) the snapshot if it changed.

Best-effort: Apple can change markup or block automated requests at any time.
The linked product page is always the source of truth.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS_FILE = ROOT / "watchlist" / "targets.json"
JSON_OUT = ROOT / "watchlist" / "latest.json"
MD_OUT = ROOT / "watchlist" / "README.md"

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
)

STATE_ICON = {
    "buy": "\U0001F3AF **BUY**",
    "in_stock": "\U0001F7E2 in stock",
    "unavailable": "\u26AA out of stock",
    "removed": "\u26AB removed",
    "unknown": "\u2754 unknown",
}


def fetch(url: str) -> tuple[int, str]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": UA,
            "Accept": "text/html,application/xhtml+xml",
            "Accept-Language": "en-CA,en;q=0.9",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        return exc.code, ""
    except Exception as exc:  # network / DNS / TLS
        print(f"  ! fetch error: {exc}", file=sys.stderr)
        return 0, ""


def parse_product(html: str) -> dict:
    """Return name/price/availability/sku from the page's JSON-LD Product block."""
    for block in re.findall(
        r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', html, re.S
    ):
        try:
            data = json.loads(block)
        except json.JSONDecodeError:
            continue
        for item in data if isinstance(data, list) else [data]:
            if not isinstance(item, dict) or item.get("@type") != "Product":
                continue
            offers = item.get("offers")
            if isinstance(offers, dict):
                offers = [offers]
            price = None
            availability = None
            sku = item.get("sku")
            for off in offers or []:
                if off.get("priceCurrency") != "CAD":
                    continue
                if off.get("price") is not None:
                    price = float(off["price"])
                availability = off.get("availability")
                sku = off.get("sku", sku)
                break
            return {
                "name": item.get("name"),
                "price_cad": price,
                "availability": availability,
                "sku": sku,
            }
    return {"name": None, "price_cad": None, "availability": None, "sku": None}


def availability_bool(value: str | None) -> bool | None:
    if not value:
        return None
    low = value.lower()
    if "instock" in low:
        return True
    if "outofstock" in low or "soldout" in low:
        return False
    return None


def is_available_heuristic(html: str) -> bool | None:
    low = html.lower()
    if "add to bag" in low or "add-to-bag" in low:
        return True
    if "currently unavailable" in low or "sold out" in low:
        return False
    return None


def check(target: dict) -> dict:
    status, html = fetch(target["url"])
    if status in (404, 410):
        return {
            "id": target["id"],
            "label": target["label"],
            "url": target["url"],
            "name": None,
            "sku": None,
            "target_cad": target.get("target_cad"),
            "price_cad": None,
            "available": False,
            "http_status": status,
            "at_or_below_target": False,
            "state": "removed",
        }

    info = parse_product(html) if html else {
        "name": None, "price_cad": None, "availability": None, "sku": None
    }
    price = info["price_cad"]
    available = availability_bool(info["availability"])
    if available is None and html:
        available = is_available_heuristic(html)

    target_price = target.get("target_cad")
    at_or_below = bool(
        price is not None and target_price is not None and price <= target_price
    )

    if available is True and at_or_below:
        state = "buy"
    elif available is True:
        state = "in_stock"
    elif available is False:
        state = "unavailable"
    else:
        state = "unknown"

    return {
        "id": target["id"],
        "label": target["label"],
        "url": target["url"],
        "name": info["name"],
        "sku": info["sku"],
        "target_cad": target_price,
        "price_cad": price,
        "available": available,
        "http_status": status,
        "at_or_below_target": at_or_below,
        "state": state,
    }


def money(value: float | None) -> str:
    return f"${value:,.2f}" if value is not None else "—"


def render_md(snapshot: dict) -> str:
    lines = [
        "# Hardware watchlist",
        "",
        "> Auto-generated by `scripts/poll-hardware.py`. Do not edit by hand.",
        "",
        f"**Last checked:** {snapshot['checked_at']}  ",
        f"**Currency:** {snapshot['currency']}",
        "",
        "| Status | Target | Listed price | Goal | Link |",
        "|---|---|---|---|---|",
    ]
    for r in snapshot["results"]:
        icon = STATE_ICON.get(r["state"], r["state"])
        goal = money(r["target_cad"]) if r["target_cad"] is not None else "—"
        note = ""
        if r["at_or_below_target"] and r["state"] != "buy":
            note = " *(≤ goal, not in stock)*"
        lines.append(
            f"| {icon} | {r['label']} | {money(r['price_cad'])}{note} "
            f"| ≤ {goal} | [open]({r['url']}) |"
        )
    lines += [
        "",
        "- **BUY** = in stock *and* listed price ≤ goal.",
        "- Price/stock come from the page's JSON-LD offer for that exact SKU.",
        "- Apple refurb inventory rotates; a listing can vanish between checks.",
        "",
        "<sub>Best-effort scraper. Apple can change markup or block automated "
        "requests at any time; the linked page is the source of truth.</sub>",
        "",
    ]
    return "\n".join(lines)


def git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)


def commit_if_changed(snapshot: dict) -> None:
    git("add", str(JSON_OUT.relative_to(ROOT)), str(MD_OUT.relative_to(ROOT)))
    if git("diff", "--cached", "--quiet").returncode == 0:
        print("No changes to commit.")
        return
    buys = [r["label"] for r in snapshot["results"] if r["state"] == "buy"]
    subject = f"chore(watchlist): hardware check {snapshot['checked_at'][:16]}"
    body = "BUY: " + ", ".join(buys) if buys else "No in-stock targets at/below goal."
    git("commit", "-m", subject, "-m", body)
    push = git("push")
    if push.returncode != 0:
        print(f"push failed:\n{push.stderr}", file=sys.stderr)
    else:
        print("Committed and pushed watchlist update.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Poll refurb Mac Studio listings.")
    parser.add_argument(
        "--commit", action="store_true", help="commit + push if the snapshot changed"
    )
    args = parser.parse_args()

    targets = json.loads(TARGETS_FILE.read_text())["targets"]
    results = [check(t) for t in targets]

    snapshot = {
        "checked_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "currency": "CAD",
        "results": results,
    }

    JSON_OUT.write_text(json.dumps(snapshot, indent=2, ensure_ascii=False) + "\n")
    MD_OUT.write_text(render_md(snapshot))

    for r in results:
        print(
            f"  {r['state']:>11}  {r['label']}  "
            f"price={r['price_cad']}  avail={r['available']}"
        )

    if args.commit:
        commit_if_changed(snapshot)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
