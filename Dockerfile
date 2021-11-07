FROM python:3-alpine

RUN addgroup -S jasmin && adduser -S -g jasmin jasmin

RUN apk --update add \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    py3-pip \
    git \
    bash 

WORKDIR /build

ENV ROOT_PATH /
ENV CONFIG_PATH /etc/jasmin
ENV RESOURCE_PATH /etc/jasmin/resource
ENV STORE_PATH /etc/jasmin/store
ENV LOG_PATH /var/log/jasmin

RUN mkdir -p ${CONFIG_PATH} ${RESOURCE_PATH} ${STORE_PATH} ${LOG_PATH}
RUN chown jasmin:jasmin ${CONFIG_PATH} ${RESOURCE_PATH} ${STORE_PATH} ${LOG_PATH}

WORKDIR /build

RUN pip install -e git+https://github.com/i9h/txamqp.git@master#egg=txamqp3
RUN pip install -e git+https://github.com/i9h/python-messaging.git@master#egg=python-messaging
RUN pip install -e git+https://github.com/i9h/smpp.pdu.git@master#egg=smpp.pdu3
RUN pip install -e git+https://github.com/i9h/smpp.twisted.git@master#egg=smpp.twisted3

COPY . .

RUN pip install .

COPY misc/config/*.cfg ${CONFIG_PATH}
COPY misc/config/resource/*.xml ${RESOURCE_PATH}

ENV UNICODEMAP_JP unicode-ascii

WORKDIR /usr/jasmin

# Change binding host for jcli, redis, and amqp
RUN sed -i '/\[jcli\]/a bind=0.0.0.0' ${CONFIG_PATH}/jasmin.cfg
RUN sed -i '/\[redis-client\]/a host=redis' ${CONFIG_PATH}/jasmin.cfg
RUN sed -i '/\[amqp-broker\]/a host=rabbitmq' ${CONFIG_PATH}/jasmin.cfg

EXPOSE 2775 8990 1401
VOLUME [${LOG_PATH}, ${CONFIG_PATH}, ${STORE_PATH}]

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["jasmind.py", "--enable-interceptor-client", "--enable-dlr-thrower", "--enable-dlr-lookup", "-u", "jcliadmin", "-p", "jclipwd"]
