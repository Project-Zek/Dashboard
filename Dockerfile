FROM elixir:alpine

# Set environment variables
ENV PHX_VERSION 1.7.11
ENV NODE_MAJOR 14.15.4
ENV ALPINE_MIRROR "https://dl-cdn.alpinelinux.org/alpine"
ENV APP_HOME /project_zek

# Create the application directory
RUN mkdir ${APP_HOME}
WORKDIR ${APP_HOME}

# Add the Alpine edge main repo to repositories
RUN echo "${ALPINE_MIRROR}/edge/main" >> /etc/apk/repositories

RUN apk add --no-cache nodejs npm inotify-tools git curl libcurl openssl-dev build-base erlang-dev

RUN set -x &&\
  mix local.hex --force &&\
  mix local.rebar --force &&\
  mix archive.install hex phx_new ${PHX_VERSION} --force

WORKDIR ${APP_HOME}

COPY dashboard/. ${APP_HOME}

RUN mix deps.get

# Compile the application
RUN mix do compile

# Run migrations and then start the Phoenix server
CMD mix ecto.migrate && mix phx.server