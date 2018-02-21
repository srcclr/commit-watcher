FROM ruby:2.3.1

RUN apt-get update -qq
RUN apt-get install -y build-essential nodejs nodejs-legacy npm mysql-client vim cmake

WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN gem install bundler && bundle install

RUN mkdir /myapp
ADD . /myapp
WORKDIR /myapp

ENTRYPOINT scripts/deploy
