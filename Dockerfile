FROM abiosoft/caddy:latest

MAINTAINER Dimitris Stafylarakis "dimitris@magnetic.io"

COPY config/Caddyfile Caddyfile
COPY site/public public

