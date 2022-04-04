FROM alpine:latest

USER root

RUN apk update \
 && apk add --no-cache curl jq \
 && rm -rf /var/cache/apk/*
