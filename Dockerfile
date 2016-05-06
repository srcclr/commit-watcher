FROM ruby:2.2.2

RUN apt-get update -qq
RUN apt-get install -y build-essential nodejs npm nodejs-legacy mysql-client vim

WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN gem install bundler && bundle install

RUN mkdir /myapp
ADD . /myapp
WORKDIR /myapp
