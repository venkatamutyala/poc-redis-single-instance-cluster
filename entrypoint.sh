#!/bin/sh

# 1. Start Redis in the background
REDIS_USER="${REDIS_USERNAME:-default}"
REDIS_LOG_LEVEL="${REDIS_LOG_LEVEL:-notice}"
CLUSTER_ANNOUNCE_HOSTNAME="${CLUSTER_ANNOUNCE_HOSTNAME:-localhost}"
CLUSTER_PREFERRED_ENDPOINT_TYPE="${CLUSTER_PREFERRED_ENDPOINT_TYPE:-ip}"

redis-server \
  --loglevel ${REDIS_LOG_LEVEL} \
  --tls-port 6380 --port 6379 \
  --tls-cert-file /certs/redis.crt \
  --tls-key-file /certs/redis.key \
  --tls-ca-cert-file /certs/ca.crt \
  --tls-auth-clients no \
  --cluster-enabled yes \
  --cluster-announce-hostname ${CLUSTER_ANNOUNCE_HOSTNAME} \
  --cluster-preferred-endpoint-type ${CLUSTER_PREFERRED_ENDPOINT_TYPE} \
  --requirepass "${REDIS_PASSWORD}" \
  --masterauth "${REDIS_PASSWORD}" \
  --appendonly yes &

# 2. Wait for Redis to be ready
until redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -u "redis://default:${REDIS_PASSWORD}@127.0.0.1:6380" ping | grep -q "PONG"; do
  echo "Waiting for Redis..."
  sleep 1
done

# 2.5. Create custom user if needed
if [ "$REDIS_USER" != "default" ]; then
  echo "✅ Creating Redis user: $REDIS_USER with password"
  redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -u "redis://default:${REDIS_PASSWORD}@127.0.0.1:6380" ACL SETUSER "$REDIS_USER" on ">$(echo $REDIS_PASSWORD)" '~*' '+@all'
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "✅ User created successfully"
  else
    echo "❌ Failed to create user (exit code: $RESULT)"
  fi
  echo "✅ Verifying user creation..."
  redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -u "redis://default:${REDIS_PASSWORD}@127.0.0.1:6380" ACL LIST | grep -i "$REDIS_USER"
  echo "⏳ Waiting for ACL changes to propagate..."
  sleep 3
fi

# 3. Assign slots if not already assigned
if ! redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -u "redis://${REDIS_USER}:${REDIS_PASSWORD}@127.0.0.1:6380" cluster info | grep -q "cluster_state:ok"; then
  echo "🔧 Assigning slots..."
  redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -u "redis://${REDIS_USER}:${REDIS_PASSWORD}@127.0.0.1:6380" cluster addslotsrange 0 16383
fi

# 4. Bring background process to foreground
wait
