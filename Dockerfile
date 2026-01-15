FROM redis:8-alpine

RUN apk add --no-cache openssl

RUN mkdir -p /certs

COPY generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/generate-certs.sh && \
    # Only generate certs if they don't exist (allows mounting external certs via volume/secret)
    test -f /certs/redis.crt || /usr/local/bin/generate-certs.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER redis
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
