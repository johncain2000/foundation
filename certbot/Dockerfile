FROM certbot/certbot:latest
COPY run-certbot.sh /run-certbot.sh
RUN chmod +x /run-certbot.sh
ENTRYPOINT ["/run-certbot.sh"]