#!/data/data/com.termux/files/usr/bin/bash
# ================================================
#   Social Media Account Finder - Auto Installer
#   For Termux (Android)
# ================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║     Social Media Account Finder              ║"
    echo "║     Auto Installer for Termux  🔧            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

step() {
    echo -e "${YELLOW}[*]${RESET} $1"
}

ok() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

err() {
    echo -e "${RED}[✗]${RESET} $1"
}

banner

# ── 1. Check we're in Termux ─────────────────────
if [ ! -d "/data/data/com.termux" ]; then
    err "This script is designed for Termux on Android."
    err "Please install Termux from F-Droid and try again."
    exit 1
fi

# ── 2. Update package lists ──────────────────────
step "Updating Termux package list..."
pkg update -y -q 2>/dev/null && ok "Package list updated." || {
    err "Failed to update packages. Continuing anyway..."
}

# ── 3. Install Python if missing ─────────────────
if ! command -v python3 &>/dev/null; then
    step "Installing Python..."
    pkg install python -y -q && ok "Python installed." || {
        err "Failed to install Python. Aborting."
        exit 1
    }
else
    ok "Python already installed: $(python3 --version)"
fi

# ── 4. Upgrade pip ───────────────────────────────
step "Upgrading pip..."
python3 -m pip install --upgrade pip -q && ok "pip upgraded." || err "pip upgrade failed. Continuing..."

# ── 5. Install required Python packages ──────────
PACKAGES=("requests" "colorama")
for pkg_name in "${PACKAGES[@]}"; do
    step "Installing Python package: ${pkg_name}..."
    python3 -m pip install "$pkg_name" -q && ok "${pkg_name} installed." || {
        err "Failed to install ${pkg_name}."
    }
done

# ── 6. Write the main Python script ──────────────
SCRIPT_PATH="$HOME/social_finder.py"
step "Writing social_finder.py to ${SCRIPT_PATH}..."

cat > "$SCRIPT_PATH" << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
Social Media Account Finder for Termux
Usage: python social_finder.py <username>
"""

import sys
import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    GREEN  = Fore.GREEN
    RED    = Fore.RED
    YELLOW = Fore.YELLOW
    CYAN   = Fore.CYAN
    BOLD   = Style.BRIGHT
    RESET  = Style.RESET_ALL
except ImportError:
    GREEN = RED = YELLOW = CYAN = BOLD = RESET = ""

PLATFORMS = [
    {"name": "GitHub",          "url": "https://github.com/{}"},
    {"name": "Twitter/X",       "url": "https://x.com/{}"},
    {"name": "Instagram",       "url": "https://www.instagram.com/{}/"},
    {"name": "TikTok",          "url": "https://www.tiktok.com/@{}"},
    {"name": "Reddit",          "url": "https://www.reddit.com/user/{}"},
    {"name": "Pinterest",       "url": "https://www.pinterest.com/{}/"},
    {"name": "LinkedIn",        "url": "https://www.linkedin.com/in/{}"},
    {"name": "YouTube",         "url": "https://www.youtube.com/@{}"},
    {"name": "Twitch",          "url": "https://www.twitch.tv/{}"},
    {"name": "Medium",          "url": "https://medium.com/@{}"},
    {"name": "Dev.to",          "url": "https://dev.to/{}"},
    {"name": "Mastodon",        "url": "https://mastodon.social/@{}"},
    {"name": "Telegram",        "url": "https://t.me/{}"},
    {"name": "Snapchat",        "url": "https://www.snapchat.com/add/{}"},
    {"name": "Tumblr",          "url": "https://{}.tumblr.com"},
    {"name": "Flickr",          "url": "https://www.flickr.com/people/{}"},
    {"name": "SoundCloud",      "url": "https://soundcloud.com/{}"},
    {"name": "Spotify",         "url": "https://open.spotify.com/user/{}"},
    {"name": "GitLab",          "url": "https://gitlab.com/{}"},
    {"name": "Bitbucket",       "url": "https://bitbucket.org/{}"},
    {"name": "HackerNews",      "url": "https://news.ycombinator.com/user?id={}"},
    {"name": "Keybase",         "url": "https://keybase.io/{}"},
    {"name": "Patreon",         "url": "https://www.patreon.com/{}"},
    {"name": "Ko-fi",           "url": "https://ko-fi.com/{}"},
    {"name": "Buy Me a Coffee", "url": "https://www.buymeacoffee.com/{}"},
    {"name": "Replit",          "url": "https://replit.com/@{}"},
    {"name": "Kaggle",          "url": "https://www.kaggle.com/{}"},
    {"name": "Steam",           "url": "https://steamcommunity.com/id/{}"},
    {"name": "Duolingo",        "url": "https://www.duolingo.com/profile/{}"},
    {"name": "Linktree",        "url": "https://linktr.ee/{}"},
    {"name": "Vimeo",           "url": "https://vimeo.com/{}"},
    {"name": "Behance",         "url": "https://www.behance.net/{}"},
    {"name": "Dribbble",        "url": "https://dribbble.com/{}"},
    {"name": "ProductHunt",     "url": "https://www.producthunt.com/@{}"},
    {"name": "Clubhouse",       "url": "https://www.joinclubhouse.com/@{}"},
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Linux; Android 11; Termux) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Mobile Safari/537.36"
    )
}

TIMEOUT    = 10
MAX_WORKERS = 20


def check_platform(platform, username):
    url = platform["url"].format(username)
    result = {"name": platform["name"], "url": url, "found": False, "error": None}
    try:
        resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT, allow_redirects=True)
        result["found"] = (resp.status_code == 200)
    except requests.exceptions.ConnectionError:
        result["error"] = "Connection error"
    except requests.exceptions.Timeout:
        result["error"] = "Timeout"
    except Exception as e:
        result["error"] = str(e)
    return result


def banner():
    print(f"""{CYAN}
╔══════════════════════════════════════════════╗
║       Social Media Account Finder            ║
║            Termux Edition  🔍                ║
╚══════════════════════════════════════════════╝{RESET}
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

    if username.startswith("@"):
        username = username[1:]

    print(f"\n{CYAN}[*] Searching for: {YELLOW}{username}{RESET}")
    print(f"{CYAN}[*] Checking {len(PLATFORMS)} platforms — please wait...{RESET}\n")

    found_accounts = []
    errors = []
    start = time.time()

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(check_platform, p, username): p for p in PLATFORMS}
        for future in as_completed(futures):
            res = future.result()
            if res["error"]:
                errors.append(res)
                print(f"  {RED}[ERROR]{RESET} {res['name']:<22} → {res['error']}")
            elif res["found"]:
                found_accounts.append(res)
                print(f"  {GREEN}[FOUND]{RESET} {BOLD}{res['name']:<22}{RESET} → {res['url']}")
            else:
                print(f"  {RED}[  -  ]{RESET} {res['name']:<22} → Not found")

    elapsed = time.time() - start

    print(f"\n{CYAN}{'═'*52}{RESET}")
    print(f"{GREEN}[+] Found {len(found_accounts)} account(s) in {elapsed:.1f}s{RESET}\n")

    if found_accounts:
        print(f"{YELLOW}{'─'*52}")
        print(f"  ✅  ACCOUNTS FOUND FOR: {username}")
        print(f"{'─'*52}{RESET}")
        for acc in found_accounts:
            print(f"  {GREEN}✓{RESET} {acc['name']:<22} {acc['url']}")

    # Save results
    output_file = f"{username}_results.txt"
    with open(output_file, "w") as f:
        f.write(f"Social Media Search Results\n")
        f.write(f"Username : {username}\n")
        f.write(f"Searched : {len(PLATFORMS)} platforms\n")
        f.write(f"Found    : {len(found_accounts)} account(s)\n")
        f.write("=" * 52 + "\n\n")
        for acc in found_accounts:
            f.write(f"[FOUND] {acc['name']:<22} {acc['url']}\n")
        if errors:
            f.write(f"\n[ERRORS]\n")
            for e in errors:
                f.write(f"[ERROR] {e['name']:<22} {e['error']}\n")

    print(f"\n{CYAN}[*] Results saved → {YELLOW}{output_file}{RESET}\n")


if __name__ == "__main__":
    main()
PYTHON_SCRIPT

chmod +x "$SCRIPT_PATH"
ok "social_finder.py written successfully."

# ── 7. Create a convenient launcher alias ─────────
BASHRC="$HOME/.bashrc"
ALIAS_LINE="alias socialfind='python3 \$HOME/social_finder.py'"

if ! grep -q "socialfind" "$BASHRC" 2>/dev/null; then
    echo "$ALIAS_LINE" >> "$BASHRC"
    ok "Alias 'socialfind' added to ~/.bashrc"
else
    ok "Alias 'socialfind' already exists in ~/.bashrc"
fi

# ── 8. Done! ─────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗"
echo -e "║         Installation Complete! ✅            ║"
echo -e "╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}Run the tool with:${RESET}"
echo -e "  ${YELLOW}  python3 ~/social_finder.py <username>${RESET}"
echo -e "  ${YELLOW}  python3 ~/social_finder.py johndoe${RESET}"
echo ""
echo -e "  ${CYAN}Or use the shortcut alias (after restarting Termux):${RESET}"
echo -e "  ${YELLOW}  socialfind <username>${RESET}"
echo ""

# ── 9. Offer to run immediately ──────────────────
read -p "$(echo -e ${YELLOW}"Would you like to search a username now? (y/n): "${RESET})" choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e ${CYAN}"Enter username: "${RESET})" uname
    python3 "$SCRIPT_PATH" "$uname"
fi
