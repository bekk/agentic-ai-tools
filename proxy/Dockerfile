FROM alpine:3
RUN apk add --no-cache squid
COPY squid.conf /etc/squid/squid.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 3128
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["squid", "-N", "-f", "/etc/squid/squid.conf"]
