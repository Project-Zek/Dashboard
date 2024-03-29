FROM elixir:alpine

ENV PHX_VERSION 1.7.11
ENV NODE_MAJOR 14.15.4
ENV ALPINE_MIRROR "https://dl-cdn.alpinelinux.org/alpine"

ENV APP_HOME /project_zek
RUN mkdir ${APP_HOME}

RUN echo "${ALPINE_MIRROR}/edge/main" >> /etc/apk/repositories
RUN apk add --no-cache nodejs npm inotify-tools 

RUN set -x &&\
  mix local.hex --force &&\
  mix local.rebar --force &&\
  mix archive.install hex phx_new ${PHX_VERSION} --force