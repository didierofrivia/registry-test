FROM alpine:latest

USER root

RUN apk update \
 && apk add --no-cache curl jq \
 && rm -rf /var/cache/apk/* \
 && curl -LO https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl \
 && chmod +x ./kubectl \
 && mv ./kubectl /usr/local/bin/kubectl
