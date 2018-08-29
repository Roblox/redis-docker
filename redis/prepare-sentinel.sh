#!/usr/bin/env bash

readonly MASTER=${MASTER:?MASTER must be set}
readonly REDIS_PASS=${REDIS_PASS:?REDIS_PASS must be set}
readonly SENTINEL_MASTER_HOST=${SENTINEL_MASTER_HOST:?SENTINEL_MASTER_HOST is required to be set}
readonly SENTINEL_MASTER_PORT=${SENTINEL_MASTER_PORT:?word}
readonly SENTINEL_QUORUM=${SENTINEL_QUORUM:?SENTINEL_QUORUM must be set}
readonly OWN_HOST=${OWN_HOST:?OWN_HOST must be set}
readonly OWN_SENTINEL_PORT=${OWN_SENTINEL_PORT:?OWN_PORT must be set}
readonly OWN_REDIS_PORT=${OWN_REDIS_PORT:?OWN_PORT must be set}
readonly FAILURE_TIMEOUT_MS=30000 # ${SENTINEL_FAILURE_TIMEOUT_MS:?word}

# ensure the cluster name is set
if [[ $MASTER == "true" ]]; then
  echo "Configuring redis master."
else
  echo "Configuring redis replica."
  cat <<EOF >> /usr/local/etc/redis/redis.conf
slaveof ${SENTINEL_MASTER_HOST} ${SENTINEL_MASTER_PORT}
# masterauth ${REDIS_PASS}
slave-announce-ip ${OWN_HOST}
slave-announce-port ${OWN_REDIS_PORT}

EOF
fi

cat /usr/local/etc/redis/redis.conf

echo "Creating sentinel.conf"
cat <<EOF > sentinel.conf
# SEE: https://redis.io/topics/sentinel#configuring-sentinel
port 5000
sentinel monitor mymaster ${SENTINEL_MASTER_HOST} ${SENTINEL_MASTER_PORT} ${SENTINEL_QUORUM}
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster ${FAILURE_TIMEOUT_MS}
sentinel parallel-syncs mymaster 1
sentinel announce-ip ${OWN_HOST}
sentinel announce-port ${OWN_SENTINEL_PORT}

# daemonize yes
# logfile "/tmp/redis-sentinel.log"
# sentinel monitor mymaster
# sentinel down-after-milliseconds mymaster
EOF

cat sentinel.conf

echo "Done"
