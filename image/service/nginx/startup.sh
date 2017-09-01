#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

FIRST_START_DONE="/docker-help-center-nginx-first-start-done"
# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

  # generate a certificate and key if files don't exists
  # https://github.com/osixia/docker-light-baseimage/blob/stable/image/service-available/:ssl-tools/assets/tool/ssl-helper
  ssl-helper ${SSL_HELPER_PREFIX} "${CONTAINER_SERVICE_DIR}/nginx/assets/certs/$SSL_CRT_FILENAME" "${CONTAINER_SERVICE_DIR}/nginx/assets/certs/$SSL_KEY_FILENAME" "${CONTAINER_SERVICE_DIR}/nginx/assets/certs/$SSL_CA_CRT_FILENAME"
  cat ${CONTAINER_SERVICE_DIR}/nginx/assets/certs/$SSL_CRT_FILENAME ${CONTAINER_SERVICE_DIR}/nginx/assets/certs/$SSL_CA_CRT_FILENAME > /nginx-combined-cert.crt

  sed -i "s|{{ CONTAINER_SERVICE_DIR }}|${CONTAINER_SERVICE_DIR}|g" ${CONTAINER_SERVICE_DIR}/nginx/assets/config/server.conf
  sed -i "s|{{ SSL_KEY_FILENAME }}|${SSL_KEY_FILENAME}|g" ${CONTAINER_SERVICE_DIR}/nginx/assets/config/server.conf

  ln -sf ${CONTAINER_SERVICE_DIR}/nginx/assets/config/server.conf /etc/nginx/sites-enabled/server.conf

  touch $FIRST_START_DONE
fi

exit 0
