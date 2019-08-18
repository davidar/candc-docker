FROM swipl:7.6.4 AS builder
RUN apt-get update && apt-get install -y build-essential
COPY . /candc

# install SOAP
WORKDIR /candc/ext
RUN apt-get install -y unzip
RUN unzip gsoap_2.8.16.zip && rm -f gsoap_2.8.16.zip
WORKDIR gsoap-2.8
RUN apt-get install -y bison flex
RUN apt-get install -y libcrypto++-dev libssl1.0-dev zlib1g-dev
RUN ./configure --prefix=/candc/ext && make && make install
WORKDIR ..
RUN rm -rf gsoap-2.8

# compile the C&C tools with SOAP support
WORKDIR /candc
RUN make
RUN make soap

# compile tokenizer and Boxer
RUN make bin/t
RUN make bin/boxer

# unzip the models for the parser
RUN tar -jxvf models-1.02.tbz2 && rm -f models-1.02.tbz2

FROM swipl:7.6.4
COPY --from=builder /candc /candc
WORKDIR /candc
CMD bin/candc --models models/boxer --candc-printer boxer | tee /dev/stderr | bin/boxer --stdin --box true
