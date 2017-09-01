#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

cd ${ZAMMAD_DIR}

if [ "${RAILS_SERVER}" == "puma" ]; then
  exec gosu ${ZAMMAD_USER}:${ZAMMAD_USER} bundle exec puma -b tcp://127.0.0.1:3000 -e ${RAILS_ENV}
elif [ "${RAILS_SERVER}" == "unicorn" ]; then
  exec gosu ${ZAMMAD_USER}:${ZAMMAD_USER} bundle exec unicorn -b 127.0.0.1 -p 3000 -c config/unicorn.rb -E ${RAILS_ENV}
fi
