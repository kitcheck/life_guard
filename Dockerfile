FROM ruby:2.2.5-alpine

RUN apk add --no-cache git bash sqlite-dev build-base

COPY . /app

WORKDIR /app/
RUN bundle install
