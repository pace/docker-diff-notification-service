FROM ubuntu:16.04
RUN apt-get update -qq
RUN apt-get install -y git make gcc ruby
RUN git clone https://github.com/tschwaerzl/aha.git
WORKDIR "aha"
RUN make
RUN make install
WORKDIR "/"
ADD ci-git-diff-notification-service.rb .
