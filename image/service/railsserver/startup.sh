#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

FIRST_START_DONE="${CONTAINER_STATE_DIR}/docker-railsserver-first-start-done"
# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

  cd ${ZAMMAD_DIR}

  log-helper info "Database config..."
  # make substitutions
  TO_REPLACE=(
    ZAMMAD_DB_HOST
    ZAMMAD_DB_NAME
    ZAMMAD_DB_USER
    ZAMMAD_DB_PASSWORD
  )

  for tag in ${TO_REPLACE[@]}
  do
    sed -i "s|{{ ${tag} }}|${!tag}|g" ${ZAMMAD_DIR}/config/database.yml
  done

  for i in {30..0}; do
    if echo "select 1;" | mysql -h ${ZAMMAD_DB_HOST} -u ${ZAMMAD_DB_USER} -p${ZAMMAD_DB_PASSWORD} ${ZAMMAD_DB_NAME}  &> /dev/null; then
      break
    fi
    echo $?
    log-helper info "Waiting database connection..."
    sleep 1
  done

  if [ "$i" = 0 ]; then
    log-helper error "Unable to connect to database."
    exit 1
  fi

  # test is zammad is installed
  ZAMMAD_INSTALLED=$(mysql -h ${ZAMMAD_DB_HOST} -u ${ZAMMAD_DB_USER} -p${ZAMMAD_DB_PASSWORD} ${ZAMMAD_DB_NAME} -e "select id from settings where name='es_url'" || true)
  if [ -n "" ]; then
    log-helper info "Update database..."
    bundle exec rake db:migrate &> /dev/null
  else
    log-helper info "Init database..."
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
  fi

  log-helper info "Elasticsearch config..."
  bundle exec rails r "Setting.set('es_url', '${ZAMMAD_ELASTICSEARCH_URL}')"
  bundle exec rake searchindex:rebuild

  log-helper info "Fix file ownership..."
  chown -R ${ZAMMAD_USER}:${ZAMMAD_USER} ${ZAMMAD_DIR}

  log-helper info "Delete logs..."
  find ${ZAMMAD_DIR}/log -iname *.log -exec rm {} \;

  touch $FIRST_START_DONE
fi

exit 0
