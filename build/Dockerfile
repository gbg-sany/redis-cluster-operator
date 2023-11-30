FROM centos:7

ENV OPERATOR=/usr/local/bin/redis-cluster-operator \
    USER_UID=1001 \
    USER_NAME=redis-cluster-operator

COPY bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}
