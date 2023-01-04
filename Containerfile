FROM ubuntu
ADD . /ruby-mmtk-builder
WORKDIR /ruby-mmtk-builder

RUN apt update
RUN apt install -y curl git sudo ruby autoconf bison gcc make zlib1g-dev \
    libffi-dev libreadline-dev libgdbm-dev libssl-dev libyaml-dev
RUN WITH_DEBUG=1 ./build.sh
