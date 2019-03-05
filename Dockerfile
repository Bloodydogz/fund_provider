FROM ubuntu:14.04
LABEL MAINTAINER=torsakch@gmail.com

ENV JRUBY_VERSION="9.1.5.0"
ENV APP_HOME="/app"
ENV RAILS_ENV="production"

RUN apt-get update \
  && apt-get -y install software-properties-common python-software-properties \
  && add-apt-repository ppa:ubuntu-toolchain-r/test \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      curl \
      libffi-dev \
      libgdbm-dev \
      libncurses-dev \
      libreadline6-dev \
      libssl-dev \
      libyaml-dev \
      zlib1g-dev \
      git \
      openssh-client \
      tar \
      mysql-client \
  && rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean

RUN add-apt-repository ppa:openjdk-r/ppa -y
RUN apt-get update
RUN apt-get install -y openjdk-8-jre

RUN apt-get update && apt-get install -y imagemagick

RUN curl https://s3.amazonaws.com/jruby.org/downloads/$JRUBY_VERSION/jruby-bin-$JRUBY_VERSION.tar.gz | tar xz -C /opt

# set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV PATH /opt/jruby-$JRUBY_VERSION/bin:$PATH
ENV BUNDLE_PATH /box

RUN gem install --no-document bundler \
 && echo gem: --no-document >> /etc/gemrc \
 && gem update --system

# install fonts-thai-tlwg for thai font
RUN apt-get update
RUN apt-get install -y xvfb fonts-thai-tlwg wget xfonts-75dpi libfontconfig

# install wkhtmlpdf
# RUN wget https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.trusty_amd64.deb
# RUN dpkg -i wkhtmltox_0.12.5-1.trusty_amd64.deb
RUN wget https://builds.wkhtmltopdf.org/0.12.6-dev/wkhtmltox_0.12.6-0.20180618.3.dev.e6d6f54.trusty_amd64.deb
RUN dpkg -i wkhtmltox_0.12.6-0.20180618.3.dev.e6d6f54.trusty_amd64.deb

RUN sudo apt-get -f install
RUN echo 'exec xvfb-run -a -s "-screen 0 640x480x16" wkhtmltopdf "$@"' | sudo tee /bin/wkhtmltopdf.sh >/dev/null
RUN chmod a+x /bin/wkhtmltopdf.sh

# install app

WORKDIR ${APP_HOME}

# cache bundle install
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
ENV JAVA_OPTS='-Xms1024m -Xmx2048m'
RUN bundle install --deployment

# Copy the application source the /app directory
ADD . ${APP_HOME}
RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN mkdir -p /app/public/assets
RUN cp -R /app/app/assets/images/* /app/public/assets

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir ./tmp/pids

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3000
