FROM alpine:latest AS gobackup-bin
RUN apk --no-cache add ca-certificates curl
ARG GOBACKUP_DIST_TAG=v3.0.0
ARG GOBACKUP_DIST_FLAVOUR=gobackup
WORKDIR /app
RUN curl -L -o gobackup.tar.gz https://github.com/${GOBACKUP_DIST_FLAVOUR}/gobackup/releases/download/${GOBACKUP_DIST_TAG}/gobackup-linux-amd64.tar.gz && tar -xvf gobackup.tar.gz

# Alpine doesn't work, archives aren't created. Probably due to musl libc
FROM fedora:44

COPY mongodb.repo /etc/yum.repos.d

RUN dnf install https://download.postgresql.org/pub/repos/yum/reporpms/F-44-x86_64/pgdg-fedora-repo-latest.noarch.rpm -y \
    && dnf install postgresql18 mariadb redis mongodb-org-tools python cronie procps-ng vim htop strace --refresh -y \
    && dnf clean all


RUN groupadd -g 1000 gobackup \
    && useradd -g gobackup -u 1000 -m -d /var/gobackup gobackup \
    && mkdir -p /etc/gobackup

COPY --from=gobackup-bin /app/gobackup /usr/local/bin
COPY gobackup.yml /etc/gobackup/gobackup.yml

RUN chown root:gobackup /etc/gobackup/gobackup.yml
RUN chmod 0440 /etc/gobackup/gobackup.yml

USER gobackup
RUN mkdir /var/gobackup/.gobackup

EXPOSE 2703
CMD ["start"]
ENTRYPOINT ["/usr/local/bin/gobackup"]
