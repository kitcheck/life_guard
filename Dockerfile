FROM 210873117884.dkr.ecr.us-east-1.amazonaws.com/ruby:2.2-alpine

COPY . /app

WORKDIR /app/
RUN bundle install
