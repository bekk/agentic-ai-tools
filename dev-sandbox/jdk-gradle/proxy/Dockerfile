FROM alpine:3
RUN apk add --no-cache squid openssl
# Dummy cert for Squid's SSL context (peek+splice mode — never presented to clients)
RUN openssl req -x509 -newkey rsa:2048 \
      -keyout /etc/squid/bump.key \
      -out /etc/squid/bump.crt \
      -days 3650 -nodes \
      -subj '/CN=squid-bump' && \
    chown squid:squid /etc/squid/bump.key /etc/squid/bump.crt
# Initialize the ssl_db required by Squid's certificate helper process
RUN /usr/lib/squid/security_file_certgen -c -s /var/cache/squid/ssl_db -M 4MB && \
    chown -R squid:squid /var/cache/squid/ssl_db
COPY squid.conf /etc/squid/squid.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 3128
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["squid", "-N", "-f", "/etc/squid/squid.conf"]
