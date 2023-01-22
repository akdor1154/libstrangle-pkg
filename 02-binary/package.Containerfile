FROM docker.io/ubuntu:22.04

RUN sed -i -e 's/^# deb-src/deb-src/' /etc/apt/sources.list
RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN apt-get -y update \
    && apt-get -y install build-essential devscripts

ARG BUILD_DEPS

RUN echo deps are container ${BUILD_DEPS}
RUN apt-get -y install ${BUILD_DEPS}