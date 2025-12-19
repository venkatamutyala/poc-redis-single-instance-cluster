#!/bin/sh

# 1. Start Redis in the background
redis-server \
  --tls-port 6379 --port 0 \
  --tls-cert-file /certs/redis.crt \
  --tls-key-file /certs/redis.key \
  --tls-ca-cert-file /certs/ca.crt \
  --cluster-enabled yes \
  --requirepass "${REDIS_PASSWORD}" \
  --masterauth "${REDIS_PASSWORD}" \
  --appendonly yes &

# 2. Wait for Redis to be ready
until redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a "${REDIS_PASSWORD}" ping | grep -q "PONG"; do
  echo "Waiting for Redis..."
  sleep 1
done

# 3. Assign slots if not already assigned
if ! redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a "${REDIS_PASSWORD}" cluster info | grep -q "cluster_state:ok"; then
  echo "🔧 Assigning slots..."
  redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a "${REDIS_PASSWORD}" cluster addslotsrange 0 16383
fi

# 4. Bring background process to foreground
wait
