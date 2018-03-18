FROM openresty/openresty:alpine-fat

RUN luarocks install busted 2.0.rc12-1

RUN mkdir /app
WORKDIR /app
COPY . /app
