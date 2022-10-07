FROM kong:2.7.1
USER root
COPY ./kong-plugin-google-cloud-functions ./kong-plugin-google-cloud-functions
RUN apk update && \
    apk add libc-dev gcc
RUN cd kong-plugin-google-cloud-functions && \
    luarocks make *.rockspec
USER kong