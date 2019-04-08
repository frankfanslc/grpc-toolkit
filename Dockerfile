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

RUN git clone --single-branch --branch network-next --depth 1 --recurse-submodules https://github.com/networknext/grpc-web /grpc-web-install
WORKDIR /grpc-web-install/
RUN make install-plugin
WORKDIR /grpc-web-install/packages/grpc-web/
RUN yarn
RUN yarn run build
RUN yarn pack --filename /grpc-web.tar.gz
RUN mkdir /grpc-web
RUN cd /grpc-web && tar -xvf /grpc-web.tar.gz

WORKDIR /temp-test
ADD test.proto /temp-test
RUN mkdir api api_grpc && \
    /protoc/bin/protoc \
      --plugin="protoc-gen-ts=$(yarn global bin)/protoc-gen-ts" \
      --js_out="import_style=commonjs:api/" \
      --grpc-web_out="import_style=commonjs+dts,mode=grpcwebtext:api_grpc/" \
      *.proto && \
    bash -c 'OUTPUT=$(grep "UNKNOWN = 0" api_grpc/test_pb.d.ts); if [ "$OUTPUT" == "" ]; then exit 1; fi'