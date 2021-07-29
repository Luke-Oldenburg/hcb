FROM ruby:2.7.3

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update -qq
RUN apt-get -y install yarn nodejs postgresql-client vim poppler-utils
  # install postgresql-client for easy importing of production database & vim
  # for easy editing of credentials
ENV EDITOR=vim

RUN gem install bundler -v 1.17.3

ADD yarn.lock /usr/src/app/yarn.lock
ADD package.json /usr/src/app/package.json
ADD Gemfile /usr/src/app/Gemfile
ADD Gemfile.lock /usr/src/app/Gemfile.lock

ENV BUNDLE_GEMFILE=Gemfile \
  BUNDLE_JOBS=4 \
  BUNDLE_PATH=/bundle

RUN bundle install
RUN yarn install --check-files

ADD . /usr/src/app
