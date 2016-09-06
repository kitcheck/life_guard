FROM ruby:2.2.5-alpine

RUN apk add --no-cache git bash build-base

COPY . /app

WORKDIR /app/
RUN bundle install
