FROM alpine:latest

RUN apk add jq unzip curl

COPY ./fetch-artifacts.sh /usr/local/bin/fetch-artifacts.sh

