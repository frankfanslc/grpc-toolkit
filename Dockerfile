FROM ubuntu:18.04

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

RUN apt update && apt install -y wget git curl unzip gnupg2 build-essential libprotobuf-dev libprotoc-dev

RUN cd /tmp && \
  wget https://dl.google.com/go/go1.11.linux-amd64.tar.gz && \
  tar -xvf go1.11.linux-amd64.tar.gz && \
  mv go /usr/local

RUN go get -u github.com/golang/protobuf/protoc-gen-go

WORKDIR /tmp
RUN mkdir /protoc
RUN curl -OL https://github.com/google/protobuf/releases/download/v3.6.0/protoc-3.6.0-linux-x86_64.zip
RUN unzip protoc-3.6.0-linux-x86_64.zip -d /protoc

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install yarn

RUN yarn global add ts-protoc-gen google-protobuf

RUN git clone --recurse-submodules https://github.com/grpc/grpc-web.git /grpc-web-install
WORKDIR /grpc-web-install/
RUN git checkout -b old-fix 626ce9702bb55d2f8841570c300fe4baa3eaaeca
RUN make install-plugin
WORKDIR /grpc-web-install/packages/grpc-web/
RUN yarn
RUN yarn run build
RUN yarn pack --filename /grpc-web.tar.gz
RUN mkdir /grpc-web
RUN cd /grpc-web && tar -xvf /grpc-web.tar.gz