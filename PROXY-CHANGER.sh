#!/bin/bash

HTTP_FILE="Ip-bot-2.0/http.txt"
HTTPS_FILE="Ip-bot-2.0/https.txt"

TEST_URL="https://api.ipify.org"
TIMEOUT=5


check_proxy() {
    local proxy=$1

    # Modified to return the total time taken for the request
    curl --silent --fail \
         --proxy "http://$proxy" \
         --connect-timeout "$TIMEOUT" \
         --max-time "$TIMEOUT" \
         -w "%{time_total}" \
         "$TEST_URL" -o /dev/null 2>&1
}


set_env_proxy() {
    local proxy=$1

    export http_proxy="http://$proxy"
    export https_proxy="http://$proxy"
    export HTTP_PROXY="http://$proxy"
    export HTTPS_PROXY="http://$proxy"
}


set_gnome_proxy() {
    local proxy=$1
    local ip="${proxy%:*}"
    local port="${proxy#*:}"

    gsettings set org.gnome.system.proxy mode 'manual'

    gsettings set org.gnome.system.proxy.http host "$ip"
    gsettings set org.gnome.system.proxy.http port "$port"

    gsettings set org.gnome.system.proxy.https host "$ip"
    gsettings set org.gnome.system.proxy.https port "$port"
}


echo "[+] Selecting a random proxy..."

# Changed from mapfile to a while loop with process substitution for real-time file reading
while read -r proxy; do
    echo -n "Testing $proxy ... "

    # Capture the speed (time_total) from the check_proxy function
    speed=$(check_proxy "$proxy")

    # Check if proxy is working AND if speed is 2.0 seconds or less
    if [ -n "$speed" ] && [ "$(echo "$speed <= 2.0" | awk '{print ($1 <= 2.0)}')" -eq 1 ]; then
        echo "WORKING (Speed: ${speed}s)"

        set_env_proxy "$proxy"
        set_gnome_proxy "$proxy"

        echo
        echo "[+] Proxy applied successfully:"
        echo "    IP   : ${proxy%:*}"
        echo "    Port : ${proxy#*:}"
        echo "    Speed: ${speed}s"
        echo "    GNOME + Terminal updated"

        exit 0
    else
        echo "DEAD/SLOW"
    fi
done < <(cat "$HTTP_FILE" "$HTTPS_FILE" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | sort -u | shuf)

echo
echo "[-] No working fast proxy found"
exit 1
