ARG UBUNTU_VERSION=18.04
FROM nvidia/cudagl:11.2.2-base-ubuntu${UBUNTU_VERSION}
ARG ROS_DISTRO=melodic
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
    && rm -rf /var/lib/apt/cache

RUN echo deb [arch=amd64] http://robotpkg.openrobots.org/packages/debian/pub "$(lsb_release -cs)" robotpkg \
        >> /etc/apt/sources.list.d/robotpkg.list \
    && wget -qO- http://robotpkg.openrobots.org/packages/debian/robotpkg.key | apt-key add - \
    && apt-get update \
    && apt-get install --assume-yes --no-install-recommends robotpkg-py27-pinocchio \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
    D2486D2DD83DB69272AFE98867170598AF249743 \
    C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 \
    && add-apt-repository --yes ppa:git-core/ppa \
    && echo deb http://packages.osrfoundation.org/gazebo/ubuntu-stable \
    "$(lsb_release -sc)" main \
    > /etc/apt/sources.list.d/gazebo-latest.list \
    && echo deb http://packages.ros.org/ros/ubuntu \
    "$(lsb_release -sc)" main \
    > /etc/apt/sources.list.d/ros-latest.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends gazebo9 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-{desktop-full,plotjuggler-ros} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

ENV PATH="/usr/local/bin${PATH:+:${PATH}}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
ENV LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}"
ENV CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
ENV DEBIAN_FRONTEND=
