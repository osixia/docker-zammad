#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

sv start /container/run/process/railsserver || exit 1

cd ${ZAMMAD_DIR}
exec gosu ${ZAMMAD_USER}:${ZAMMAD_USER} bundle exec script/websocket-server.rb -b 127.0.0.1 -p 6042 start
