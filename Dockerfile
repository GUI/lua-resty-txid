FROM openresty/openresty:alpine-fat

# For CI envrionment.
RUN apk add --update git openssh-client

# For luarocks upload.
RUN apk add --update zip

# Install busted for testing.
RUN luarocks install busted 2.0.rc12-1

# Install luacheck for linting.
RUN luarocks install luacheck 0.21.2-1

RUN mkdir /app
WORKDIR /app
COPY . /app
