#!/usr/bin/env bash

docker exec -it redis sh -c '
  export FLAGS="--tls --insecure --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a my-secret-password"
  
  echo "--- Cluster Info ---"
  redis-cli $FLAGS cluster info
  
  echo "--- Setting Data ---"
  redis-cli $FLAGS set foo bar
  
  echo "--- Getting Data ---"
  redis-cli $FLAGS get foo
'