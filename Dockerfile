ARG UBUNTU_VERSION=bionic
FROM ubuntu:${UBUNTU_VERSION} AS base-linux-amd64
SHELL ["/bin/bash", "-c"]
WORKDIR /root/

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# 3. Install common prerequisites.
RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        build-essential ca-certificates checkinstall cmake curl dpkg-dev \
        g++ gcc git gnupg gnupg2 libtool libssl-dev make \
        software-properties-common doxygen graphviz libeigen3-dev \
        liburdfdom-dev python-dev unzip wget \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache/

RUN echo deb [arch=amd64] http://robotpkg.openrobots.org/packages/debian/pub "$(lsb_release -cs)" robotpkg \
        >> /etc/apt/sources.list.d/robotpkg.list \
    && wget -qO- http://robotpkg.openrobots.org/packages/debian/robotpkg.key | apt-key add - \
    && apt-get update \
    && apt-get install --assume-yes --no-install-recommends robotpkg-py27-pinocchio \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

ENV PATH="/usr/local/bin${PATH:+:${PATH}}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
ENV LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}"
ENV CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
