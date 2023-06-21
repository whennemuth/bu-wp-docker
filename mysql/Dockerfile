FROM bitnami/mysql:8.0.33-debian-11-r20

USER root

RUN apt update && apt install pv -y

USER 1001

COPY ./memory-reduction.cnf /opt/bitnami/mysql/conf/memory-reduction.cnf

COPY ./populate.sh /usr/local/bin/populate.sh