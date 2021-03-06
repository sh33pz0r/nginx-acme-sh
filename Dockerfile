FROM nginx:1.12

RUN apt-get update && \
    apt-get install -y python-pip curl cron socat && \
    curl https://get.acme.sh | sh && \
    pip install dns-lexicon && \

    mkdir -p /etc/nginx/ssl && \
    rm /etc/nginx/conf.d/default.conf && \
    rm /etc/nginx/nginx.conf && \

    apt-get autoremove -y -qq && \
	apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/*

COPY conf/http.conf /etc/nginx/conf.d/http.conf
COPY conf/https.conf /etc/nginx/conf.d/https.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY ./entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
