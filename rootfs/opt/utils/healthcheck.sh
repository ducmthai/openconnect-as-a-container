#!/command/with-contenv sh
set -e -u -o pipefail

http_proxy=http://$(hostname -i):${HTTP_PROXY_PORT} wget -Y on -q -O - ifconfig.co/ip | grep -v  "$1" || exit 1