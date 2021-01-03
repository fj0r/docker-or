#!/usr/bin/with-contenv bash
echo >&2 "starting watcher"

inotifywait -qrm \
  -e modify,move,create,delete \
  --exclude '.*(\.pyc|~)' \
  --exclude .swp \
  /etc/openresty \
  | while read EVENT; do
    echo $EVENT
    openresty -t
    if [ $? -eq 0 ]; then
        echo "[$(date -Iseconds)] Reloading Openresty Configuration"
        openresty -s reload
    fi
done