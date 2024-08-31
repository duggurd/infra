FROM golang:1.21-alpine3.18 as builder
# Do not remove `git` here, it is required for getting runner version when executing `make build`
RUN apk add --no-cache make git

COPY . /opt/src/act_runner
WORKDIR /opt/src/act_runner

RUN make clean && make build

FROM docker:dind-rootless
USER root
RUN apk add --no-cache \
  git bash supervisor

COPY --from=builder /opt/src/act_runner/act_runner /usr/local/bin/act_runner
COPY /scripts/supervisord.conf /etc/supervisord.conf
COPY /scripts/run.sh /opt/act/run.sh
COPY /scripts/rootless.sh /opt/act/rootless.sh
COPY ./act_runner_config.yaml /etc/act_runner/config.yaml

RUN mkdir /data \
    && chown rootless:rootless /data

# USER rootless
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]