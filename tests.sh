#!/usr/bin/env bash

REDIS_PASSWORD="${REDIS_PASSWORD:-my-secret-password}"

docker exec -e REDIS_PASSWORD="$REDIS_PASSWORD" redis sh -c '
  export FLAGS="--tls --insecure --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a $REDIS_PASSWORD"
  
  echo "--- Cluster Info ---"
  redis-cli $FLAGS cluster info
  
  echo "--- Setting Data ---"
  redis-cli $FLAGS set foo bar
  
  echo "--- Getting Data ---"
  redis-cli $FLAGS get foo
'