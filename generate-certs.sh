#!/bin/sh
set -e

CERT_DIR="/certs"
mkdir -p $CERT_DIR

# 1. Generate CA
openssl req -x509 -new -nodes -sha256 -days 3650 -newkey rsa:2048 \
  -keyout $CERT_DIR/ca.key \
  -out $CERT_DIR/ca.crt \
  -subj "/CN=Redis-Internal-CA"

# 2. Create an extensions file for the certificate
cat > $CERT_DIR/redis.ext << EOF
subjectAltName = DNS:localhost,DNS:redis-cluster,DNS:mmos-redis,DNS:mmos-redis.mmos-dev.svc.cluster.local,IP:127.0.0.1
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOF

# 3. Create Server Key and CSR
openssl req -new -nodes -newkey rsa:2048 \
  -keyout $CERT_DIR/redis.key \
  -out $CERT_DIR/redis.csr \
  -subj "/CN=redis-cluster"

# 4. Sign the Server Cert with CA, properly including SANs
openssl x509 -req -sha256 -days 365 \
  -in $CERT_DIR/redis.csr \
  -CA $CERT_DIR/ca.crt \
  -CAkey $CERT_DIR/ca.key \
  -CAcreateserial \
  -out $CERT_DIR/redis.crt \
  -extfile $CERT_DIR/redis.ext

# 5. Clean up temporary files
rm -f $CERT_DIR/redis.csr $CERT_DIR/redis.ext

# 6. Set permissions so the 'redis' user (UID 999) can read them
chown -R 999:999 $CERT_DIR
chmod 644 $CERT_DIR/redis.crt $CERT_DIR/ca.crt
chmod 600 $CERT_DIR/redis.key $CERT_DIR/ca.key

echo "✅ Certificates generated in $CERT_DIR with SANs:"
echo "   - localhost"
echo "   - redis-cluster"
echo "   - mmos-redis"
echo "   - mmos-redis.mmos-dev.svc.cluster.local"
echo "   - 127.0.0.1"
