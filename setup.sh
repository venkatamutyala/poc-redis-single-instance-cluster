#!/usr/bin/env bash

docker run --rm -it \
  --name redis \
  -p 6379:6379 \
  -v "$(pwd)/certs":/certs \
  redis:8-alpine \
  /bin/sh -c '
    # 1. Install OpenSSL
    apk add --no-cache openssl > /dev/null

    # 2. Generate Certs ONLY if they do not exist
    if [ ! -f /certs/redis.crt ]; then
      echo "⚡ Generating fresh certificates..."
      
      # CA
      openssl req -x509 -new -nodes -sha256 -days 3650 -newkey rsa:2048 \
        -keyout /certs/ca.key -out /certs/ca.crt -subj "/CN=LocalRedisCA"
      
      # Server Cert (Subject = localhost and IP 127.0.0.1)
      openssl req -new -nodes -newkey rsa:2048 \
        -keyout /certs/redis.key -out /certs/redis.csr -subj "/CN=localhost" \
        -addext "subjectAltName = DNS:localhost,IP:127.0.0.1"

      # Sign it
      openssl x509 -req -sha256 -days 365 \
        -in /certs/redis.csr \
        -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial \
        -out /certs/redis.crt \
        -extfile /etc/ssl/openssl.cnf -extensions v3_req
      
      # Fix permissions so Redis user can read them
      chown redis:redis /certs/*
      chmod 644 /certs/*
    else
      echo "♻️  Using existing certificates found in /certs"
    fi

    # 3. Start Redis (Background)
    echo "🚀 Starting Redis..."
    redis-server \
      --tls-port 6379 --port 0 \
      --tls-cert-file /certs/redis.crt \
      --tls-key-file /certs/redis.key \
      --tls-ca-cert-file /certs/ca.crt \
      --cluster-enabled yes \
      --cluster-node-timeout 5000 \
      --requirepass "my-secret-password" \
      --masterauth "my-secret-password" \
      --appendonly yes &

    # 4. Wait for Redis to be up
    echo "⏳ Waiting for Redis to accept connections..."
    until redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a "my-secret-password" ping | grep -q "PONG"; do
      sleep 1
    done

    # 5. Initialize Cluster Slots
    echo "🔧 Assigning slots..."
    redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a "my-secret-password" \
      cluster addslotsrange 0 16383 > /dev/null

    echo "✅ READY! Connection string: localhost:6379 (Password: my-secret-password)"
    
    wait
  '