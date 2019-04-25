FROM ubuntu:18.04

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

ADD test.proto /temp-test/test.proto
RUN apt update && \
    apt install -y wget git curl unzip gnupg2 build-essential libprotobuf-dev libprotoc-dev && \
    cd /tmp && \
    wget https://dl.google.com/go/go1.11.linux-amd64.tar.gz && \
    tar -xvf go1.11.linux-amd64.tar.gz && \
    mv go /usr/local && \
    go get -u github.com/golang/protobuf/protoc-gen-go && \
    cd /tmp && \
    mkdir /protoc && \
    curl -OL https://github.com/google/protobuf/releases/download/v3.6.0/protoc-3.6.0-linux-x86_64.zip && \
    unzip protoc-3.6.0-linux-x86_64.zip -d /protoc && \
    (curl -sL https://deb.nodesource.com/setup_10.x | bash -) && \
    apt-get install -y nodejs && \
    (curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -) && \
    (echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list) && \
    apt-get update && apt-get install yarn && \
    yarn global add ts-protoc-gen google-protobuf && \
    git clone --single-branch --branch network-next --depth 1 --recurse-submodules https://github.com/networknext/grpc-web /grpc-web-install && \
    cd /grpc-web-install/ && \
    make install-plugin && \
    cd /grpc-web-install/packages/grpc-web/ && \
    yarn && \
    yarn run build && \
    yarn pack --filename /grpc-web.tar.gz && \
    mkdir /grpc-web && \
    cd /grpc-web && tar -xvf /grpc-web.tar.gz && \
    rm -Rf /grpc-web-install && \
    cd /temp-test && \
    mkdir api api_grpc && \
    /protoc/bin/protoc \
      --plugin="protoc-gen-ts=$(yarn global bin)/protoc-gen-ts" \
      --js_out="import_style=commonjs:api/" \
      --grpc-web_out="import_style=commonjs+dts,mode=grpcwebtext:api_grpc/" \
      *.proto && \
    bash -c 'OUTPUT=$(grep "UNKNOWN = 0" api_grpc/test_pb.d.ts); if [ "$OUTPUT" == "" ]; then exit 1; fi' && \
    cd / && \
    apt remove -y wget git curl unzip gnupg2 build-essential libprotobuf-dev libprotoc-dev && \
    apt autoremove -y && \
    rm -Rf /temp-test