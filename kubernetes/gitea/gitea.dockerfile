FROM alpine:latest

RUN apk update && apk add gitea -y --no-cache