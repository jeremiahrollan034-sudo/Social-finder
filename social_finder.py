#!/usr/bin/env python3
"""
Social Media Account Finder for Termux
Usage: python social_finder.py <username>
Requires: pip install requests colorama
"""

import sys
import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# Try to import colorama for colored output
try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    GREEN  = Fore.GREEN
    RED    = Fore.RED
    YELLOW = Fore.YELLOW
    CYAN   = Fore.CYAN
    RESET  = Style.RESET_ALL
except ImportError:
    GREEN = RED = YELLOW = CYAN = RESET = ""

# --- Platform definitions ---
# Each entry: (platform_name, url_template, expected_status_or_text)
# "check": "status"  -> checks HTTP status code (200 = found)
# "check": "text"    -> checks if a string is ABSENT (profile not found page)

PLATFORMS = [
    {"name": "GitHub",         "url": "https://github.com/{}",                    "check": "status"},
    {"name": "Twitter/X",      "url": "https://x.com/{}",                         "check": "status"},
    {"name": "Instagram",      "url": "https://www.instagram.com/{}/",            "check": "status"},
    {"name": "TikTok",         "url": "https://www.tiktok.com/@{}",               "check": "status"},
    {"name": "Reddit",         "url": "https://www.reddit.com/user/{}",           "check": "status"},
    {"name": "Pinterest",      "url": "https://www.pinterest.com/{}/",            "check": "status"},
    {"name": "LinkedIn",       "url": "https://www.linkedin.com/in/{}",           "check": "status"},
    {"name": "YouTube",        "url": "https://www.youtube.com/@{}",              "check": "status"},
    {"name": "Twitch",         "url": "https://www.twitch.tv/{}",                 "check": "status"},
    {"name": "Medium",         "url": "https://medium.com/@{}",                   "check": "status"},
    {"name": "Dev.to",         "url": "https://dev.to/{}",                        "check": "status"},
    {"name": "Mastodon",       "url": "https://mastodon.social/@{}",              "check": "status"},
    {"name": "Telegram",       "url": "https://t.me/{}",                          "check": "status"},
    {"name": "Snapchat",       "url": "https://www.snapchat.com/add/{}",          "check": "status"},
    {"name": "Tumblr",         "url": "https://{}.tumblr.com",                    "check": "status"},
    {"name": "Flickr",         "url": "https://www.flickr.com/people/{}",         "check": "status"},
    {"name": "SoundCloud",     "url": "https://soundcloud.com/{}",                "check": "status"},
    {"name": "Spotify",        "url": "https://open.spotify.com/user/{}",         "check": "status"},
    {"name": "GitLab",         "url": "https://gitlab.com/{}",                    "check": "status"},
    {"name": "Bitbucket",      "url": "https://bitbucket.org/{}",                 "check": "status"},
    {"name": "HackerNews",     "url": "https://news.ycombinator.com/user?id={}",  "check": "status"},
    {"name": "Keybase",        "url": "https://keybase.io/{}",                    "check": "status"},
    {"name": "Patreon",        "url": "https://www.patreon.com/{}",               "check": "status"},
    {"name": "Ko-fi",          "url": "https://ko-fi.com/{}",                     "check": "status"},
    {"name": "Buy Me a Coffee","url": "https://www.buymeacoffee.com/{}",          "check": "status"},
    {"name": "Replit",         "url": "https://replit.com/@{}",                   "check": "status"},
    {"name": "Kaggle",         "url": "https://www.kaggle.com/{}",                "check": "status"},
    {"name": "Steam",          "url": "https://steamcommunity.com/id/{}",         "check": "status"},
    {"name": "Duolingo",       "url": "https://www.duolingo.com/profile/{}",      "check": "status"},
    {"name": "Linktree",       "url": "https://linktr.ee/{}",                     "check": "status"},
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Linux; Android 11; Termux) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Mobile Safari/537.36"
    )
}

TIMEOUT = 10  # seconds per request
MAX_WORKERS = 15


def check_platform(platform: dict, username: str) -> dict:
    url = platform["url"].format(username)
    result = {
        "name": platform["name"],
        "url": url,
        "found": False,
        "error": None,
    }
    try:
        resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT, allow_redirects=True)
        if platform["check"] == "status":
            result["found"] = resp.status_code == 200
        elif platform["check"] == "text":
            # found if the "not found" text is absent
            needle = platform.get("not_found_text", "")
            result["found"] = needle not in resp.text
    except requests.exceptions.ConnectionError:
        result["error"] = "Connection error"
    except requests.exceptions.Timeout:
        result["error"] = "Timeout"
    except Exception as e:
        result["error"] = str(e)
    return result


def banner():
    print(f"""{CYAN}
╔══════════════════════════════════════════╗
║      Social Media Account Finder         ║
║         Termux Edition  🔍               ║
╚══════════════════════════════════════════╝{RESET}
""")


def main():
    banner()

    if len(sys.argv) < 2:
        username = input(f"{YELLOW}Enter username to search: {RESET}").strip()
    else:
        username = sys.argv[1].strip()

    if not username:
        print(f"{RED}[!] No username provided. Exiting.{RESET}")
        sys.exit(1)

    # Sanitize: remove @ if user typed @username
    if username.startswith("@"):
        username = username[1:]

    print(f"\n{CYAN}[*] Searching for: {YELLOW}{username}{RESET}")
    print(f"{CYAN}[*] Checking {len(PLATFORMS)} platforms...{RESET}\n")

    found_accounts = []
    not_found = []
    errors = []

    start = time.time()

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {
            executor.submit(check_platform, p, username): p for p in PLATFORMS
        }
        for future in as_completed(futures):
            res = future.result()
            if res["error"]:
                errors.append(res)
                print(f"  {RED}[ERROR]{RESET} {res['name']:20s} → {res['error']}")
            elif res["found"]:
                found_accounts.append(res)
                print(f"  {GREEN}[FOUND]{RESET} {res['name']:20s} → {res['url']}")
            else:
                not_found.append(res)
                print(f"  {RED}[  -  ]{RESET} {res['name']:20s} → Not found")

    elapsed = time.time() - start

    print(f"\n{CYAN}{'═'*50}{RESET}")
    print(f"{GREEN}[+] Found {len(found_accounts)} account(s) in {elapsed:.1f}s{RESET}\n")

    if found_accounts:
        print(f"{YELLOW}{'─'*50}")
        print(f"  RESULTS FOR: {username}")
        print(f"{'─'*50}{RESET}")
        for acc in found_accounts:
            print(f"  {GREEN}✓{RESET} {acc['name']:20s} {acc['url']}")

    # Save results to file
    output_file = f"{username}_results.txt"
    with open(output_file, "w") as f:
        f.write(f"Social Media Search Results for: {username}\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Found {len(found_accounts)} account(s):\n\n")
        for acc in found_accounts:
            f.write(f"[FOUND] {acc['name']:20s} {acc['url']}\n")
        if errors:
            f.write(f"\nErrors ({len(errors)}):\n")
            for e in errors:
                f.write(f"[ERROR] {e['name']:20s} {e['error']}\n")

    print(f"\n{CYAN}[*] Results saved to: {YELLOW}{output_file}{RESET}\n")


if __name__ == "__main__":
    main()
