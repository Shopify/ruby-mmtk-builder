FROM ubuntu
ADD . /ruby-mmtk-builder
WORKDIR /ruby-mmtk-builder

RUN apt update
RUN apt install -y curl git build-essential sudo ruby
RUN ./build.sh