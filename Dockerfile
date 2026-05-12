FROM alpine as git_httpd

ENTRYPOINT ["/entrypoint/entrypoint.sh"]
WORKDIR /var/www/localhost/
RUN apk --no-cache add git apache2-proxy py3-flask py3-six py3-waitress

#Remove in final build
RUN apk add bash nano

RUN apk --no-cache add py3-setuptools && \
    cd /opt/ && \
    git clone https://github.com/bloomberg/python-github-webhook.git && \
    cd /opt/python-github-webhook && \
    python3 setup.py install && \
    apk --no-cache del py3-setuptools

COPY conf.d /etc/apache2/conf.d

COPY run.py /opt/python-github-webhook/
COPY hooks /opt/python-github-webhook/hooks
COPY entrypoint /entrypoint
