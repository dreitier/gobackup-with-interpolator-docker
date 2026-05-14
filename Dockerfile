# interpolator image
ARG INTERPOLATOR_TAG=1.0.0
FROM dreitier/interpolator:${INTERPOLATOR_TAG} AS interpolator-bin

FROM alpine:latest AS gobackup-bin
RUN apk --no-cache add ca-certificates curl
ARG GOBACKUP_DIST_TAG=v1.0.1
ARG GOBACKUP_DIST_FLAVOUR=huacnlee
WORKDIR /app
RUN curl -L -o gobackup.tar.gz https://github.com/${GOBACKUP_DIST_FLAVOUR}/gobackup/releases/download/${GOBACKUP_DIST_TAG}/gobackup-linux-amd64.tar.gz && tar -xvf gobackup.tar.gz

# Alpine doesn't work, archives aren't created. Probably due to musl libc
FROM fedora:44
WORKDIR /app

COPY mongodb.repo /etc/yum.repos.d

RUN dnf install https://download.postgresql.org/pub/repos/yum/reporpms/F-44-x86_64/pgdg-fedora-repo-latest.noarch.rpm -y \
    && dnf install postgresql18 mariadb redis mongodb-org-tools python cronie procps-ng vim htop strace --refresh -y \
    && dnf clean all

COPY --from=interpolator-bin /app/interpolator .
COPY --from=gobackup-bin /app/gobackup .

RUN mkdir /etc/gobackup
COPY entrypoint.sh .

CMD ["perform"]
ENTRYPOINT ["/app/entrypoint.sh"]