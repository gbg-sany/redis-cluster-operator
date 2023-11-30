FROM centos:7

ARG ARCH=amd64
ARG LOCALBIN=/usr/local/bin
ARG PROJECT_NAME=redis-cluster-operator

ENV OPERATOR=${LOCALBIN}/${PROJECT_NAME} \
    USER_UID=1001 \
    USER_NAME=${PROJECT_NAME}

COPY bin ${LOCALBIN}
RUN mv ${OPERATOR}-linux-${ARCH} ${OPERATOR}
RUN ${LOCALBIN}/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}
