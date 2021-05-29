ARG UBUNTU_VERSION=16.04
FROM nvidia/cudagl:11.2.2-base-ubuntu${UBUNTU_VERSION} as base
ARG ROS_DISTRO=kinetic
SHELL ["/bin/bash", "-c"]
WORKDIR /root/

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install some basic utilities.
RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        build-essential ca-certificates checkinstall cmake curl dpkg-dev \
        g++ gcc git gnupg gnupg2 libtool libssl-dev make \
        software-properties-common doxygen graphviz libeigen3-dev \
        liburdfdom-dev python-dev unzip wget \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

# Add Gazebo and ROS to APT sources.
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
    D2486D2DD83DB69272AFE98867170598AF249743 \
    C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 \
    && echo deb http://packages.osrfoundation.org/gazebo/ubuntu-stable \
    "$(lsb_release -sc)" main \
    > /etc/apt/sources.list.d/gazebo-latest.list \
    && echo deb http://packages.ros.org/ros/ubuntu \
    "$(lsb_release -sc)" main \
    > /etc/apt/sources.list.d/ros-latest.list

# Install Gazebo.
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends gazebo9 \
#     && rm -rf /var/lib/apt/lists/* \
#     && rm -rf /var/lib/apt/cache

# Install ROS.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-{desktop-full,plotjuggler} \
    python-{rosdep,wstool} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

# # Update git and git tools and install bug utilities.
RUN add-apt-repository ppa:git-core/ppa \
    && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash-completion git git-lfs tig vim \
        gdb valgrind \
    # python-{ipython,matplotlib,numpy,pudb,pytest,scipy,pip} \
        python-{pudb,pytest,scipy,pip} \
    && pip install xmltodict \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

# Install Pinocchio.
# RUN echo deb [arch=amd64] http://robotpkg.openrobots.org/packages/debian/pub "$(lsb_release -cs)" robotpkg \
#         >> /etc/apt/sources.list.d/robotpkg.list \
#     && wget -qO- http://robotpkg.openrobots.org/packages/debian/robotpkg.key | apt-key add - \
#     && apt-get update \
#     && apt-get install --assume-yes --no-install-recommends robotpkg-py27-pinocchio \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/* \
#     && rm -rf /var/lib/apt/cache

# COPY miso-test-ubuntu.list /etc/apt/sources.list.d
# RUN apt-get update && \
#     apt-get -y install g++-8 && \
#     # update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 20 && \
#     # update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 20 && \
#     rm -rf /var/lib/apt/lists/* && \
#     mkdir /var/lib/apt/lists/partial

# Install OpenRAVE dependencies
FROM base AS build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ann-tools \
        build-essential \
        checkinstall \
        git \
        openssh-client \
        libann-dev \
        libassimp-dev \
        libavcodec-dev \
        libavformat-dev \
        libcairo2-dev \
        libccd-dev \
        libcollada-dom2.4-dp* \
        libeigen3-dev \
        libfaac-dev \
        libfcl-0.5-dev \
        libflann-dev \
        libfreetype6-dev \
        libjasper-dev \
        liblapack-dev \
        libglew-dev \
        libgmp-dev \
        libgsm1-dev \
        libminizip-dev \
        libmpfi-dev \
        libmpfr-dev \
        libmysqlclient-dev \
        libode-dev \
        libogg-dev \
        libopenscenegraph-dev \
        libopenthreads-dev \
        libpcre++-dev \
        libpoppler-glib-dev \
        libqhull-dev \
        libsdl2-dev \
        libsoqt4-dev \
        libswscale-dev \
        libtiff5-dev \
        libtinyxml-dev \
        libvorbis-dev \
        libx264-dev \
        libxml2-dev \
        libxrandr-dev \
        libxvidcore-dev && \
    rm -rf /var/lib/apt/lists/* \
    && mkdir /var/lib/apt/lists/partial \
    && mkdir -p -m 0700 ~/.ssh && ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts

FROM build AS cmake-source
RUN SRC_DIR="/usr/local/src/cmake/" && \
    mkdir -p "${SRC_DIR}" && \
    git clone https://github.com/Kitware/CMake.git "${SRC_DIR}"

FROM build AS ompi-source
RUN SRC_DIR="/usr/local/src/ompi/" && \
    mkdir -p "${SRC_DIR}" && \
    git clone https://github.com/open-mpi/ompi.git "${SRC_DIR}"

FROM build AS openscenegraph-source
RUN SRC_DIR="/usr/local/src/openscenegraph" && \
    mkdir -p "${SRC_DIR}" && \
    git clone https://github.com/openscenegraph/OpenSceneGraph.git "${SRC_DIR}"

FROM build AS openrave-source
RUN --mount=type=ssh \
    SRC_DIR="/usr/local/src/openrave" && \
    mkdir -p "${SRC_DIR}" && \
    git clone git@github.com:MisoRobotics/openrave.git "${SRC_DIR}"

FROM build AS trajopt-source
RUN --mount=type=ssh \
    SRC_DIR="/usr/local/src/trajopt" && \
    mkdir -p "${SRC_DIR}" && \
    git clone git@github.com:MisoRobotics/trajopt.git "${SRC_DIR}"

FROM build AS protobuf3-source
RUN SRC_DIR="/usr/local/src" && \
    PROTOBUF_ARCHIVE="protobuf-all-3.12.3.tar.gz" && \
    mkdir -p "${SRC_DIR}" && \
    curl -sSOL "https://github.com/protocolbuffers/protobuf/releases/download/v3.12.3/${PROTOBUF_ARCHIVE}" && \
    tar xvzf "${PROTOBUF_ARCHIVE}" -C "${SRC_DIR}" && \
    rm "${PROTOBUF_ARCHIVE}"

FROM build AS cmake-build
COPY --from=cmake-source /usr/local/src/cmake /usr/local/src/cmake
RUN CMAKE_VERSION="3.14.5" && \
    CMAKE_DEPENDS='procps, libarchive13, libc6 (>= 2.23), libcurl3 (>= 7.47.0), libexpat1 (>= 2.1.0), libgcc1 (>= 1:9.1), libjsoncpp1, libstdc++6 (>= 9.1), zlib1g (>= 1:1.2.8)' && \
    SRC_DIR="/usr/local/src/cmake" && \
    cd "${SRC_DIR}" && \
    git checkout "v${CMAKE_VERSION}" && \
    BLD_DIR=$(mktemp -d) && \
    cd "${BLD_DIR}" && \
    ${SRC_DIR}/bootstrap && make -j$(nproc) && \
    PKG="cmake" eval 'checkinstall --default --nodoc --provides ${PKG} --pkgsource ${PKG} --pkgname ${PKG} --pkgversion="${CMAKE_VERSION}" --requires="${CMAKE_DEPENDS}" --maintainer="Ryan Sinnet \<rsinnet@misorobotics.com\>"' && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    cd && \
    rm -rf "${BLD_DIR}"

FROM build AS ompi-build
COPY --from=ompi-source /usr/local/src/ompi /usr/local/src/ompi
RUN apt-get update && apt-get install -y autoconf flex && \
    SRC_DIR="/usr/local/src/ompi" && \
    cd "${SRC_DIR}" && \
    git checkout v4.0.1 && \
    ./autogen.pl && \
    ./configure --prefix=/usr/local && \
    make -j20 && \
    PKG="ompi" eval 'checkinstall --default --nodoc --provides ${PKG} --pkgsource ${PKG} --pkgname ${PKG} --pkgversion="4.0.1" --maintainer="Ryan Sinnet \<rsinnet@misorobotics.com\>"' && \
    mkdir -p /dist && \
    mv *.deb /dist

FROM cmake-build AS openscenegraph-build
COPY --from=openscenegraph-source /usr/local/src/openscenegraph /usr/local/src/openscenegraph
RUN SRC_DIR="/usr/local/src/openscenegraph" && \
    cd "${SRC_DIR}" && \
    git checkout OpenSceneGraph-3.4 && \
    BLD_DIR=$(mktemp -d) && \
    cd "${BLD_DIR}" && \
    cmake -DDESIRED_QT_VERSION=4 "${SRC_DIR}" && \
    make -j$(nproc) && \
    PKG="libopenscenegraph-dev" PKG_VERSION="3.4" eval 'checkinstall --default --nodoc --provides ${PKG} --pkgsource ${PKG} --pkgname ${PKG} --pkgversion=${PKG_VERSION} --requires="libxrandr2, gir1.2-poppler-0.18, libsdl2-2.0-0, libtiffxx5" --maintainer="Ryan Sinnet \<rsinnet@misorobotics.com\>" make install install_ld_conf' && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    cd && \
    rm -rf "${BLD_DIR}"

FROM cmake-build AS openrave-build
COPY --from=openrave-source /usr/local/src/openrave /usr/local/src/openrave
RUN SRC_DIR="/usr/local/src/openrave" && \
    cd "${SRC_DIR}" && \
    git checkout 7c5f5e27eec2b2ef10aa63fbc519a998c276f908 && \
    BLD_DIR=$(mktemp -d) && \
    cd "${BLD_DIR}" && \
    cmake -DOPENRAVE_PLUGIN_QTOSGRAVE=0 "${SRC_DIR}" && \
    make -j$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l) && \
    PKG="openrave" PKG_VERSION="0.9" eval 'checkinstall --default --nodoc --provides $PKG --pkgsource $PKG --pkgname $PKG --pkgversion=${PKG_VERSION}' && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    cd
    # && \
    #rm -rf "${SRC_DIR}" "${BLD_DIR}"

FROM openrave-build AS osqp-python-build
# Install osqp-python
RUN SRC_DIR=$(mktemp -d) && \
    git clone --depth=1 --recurse-submodules https://github.com/oxfordcontrol/osqp-python -b v0.5.0 "${SRC_DIR}" && \
    cd "${SRC_DIR}" && \
    python setup.py bdist_egg && \
    mkdir -p /dist && \
    mv dist/*.egg /dist && \
    cd && \
    rm -rf "${SRC_DIR}"

FROM osqp-python-build AS osqp-c-build
RUN SRC_DIR=$(mktemp -d) && \
    git clone --depth=1 --recurse-submodules https://github.com/oxfordcontrol/osqp -b v0.5.0 "${SRC_DIR}" && \
    BLD_DIR=$(mktemp -d) && \
    cd "${BLD_DIR}" && \
    cmake "${SRC_DIR}" && \
    make -j$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l) && \
    PKG="osqp-c" PKG_VERSION="0.5.0" eval 'checkinstall --default --nodoc --provides $PKG --pkgsource $PKG --pkgname $PKG --pkgversion=${PKG_VERSION} --maintainer="Ryan Sinnet \<rsinnet@misorobotics.com\>" make install' && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    cd && \
    rm -rf "${SRC_DIR}" "${BLD_DIR}"

FROM osqp-c-build AS trajopt-build
COPY --from=trajopt-source /usr/local/src/trajopt /usr/local/src/trajopt
RUN --mount=type=ssh \
    SRC_DIR="/usr/local/src/trajopt" && \
    cd "${SRC_DIR}" && \
    git checkout master && \
    BLD_DIR="$(mktemp -d)" && \
    cd "${BLD_DIR}" && \
    cmake "${SRC_DIR}" && \
    make -j$(nproc) && \
    PKG="miso-trajopt" PKG_VERSION="0.1" eval 'checkinstall --default --nodoc --provides $PKG --pkgsource $PKG --pkgname $PKG --pkgversion=${PKG_VERSION}' && \
    apt-mark hold miso-trajopt && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    cd && \
    rm -rf "${BLD_DIR}" && \
    echo '/usr/local/lib/python2.7/dist-packages' > /etc/ld.so.conf.d/trajopt.conf && \
    ldconfig

FROM trajopt-build AS protobuf3-build
COPY --from=protobuf3-source /usr/local/src/protobuf-3.12.3 /usr/local/src/protobuf-3.12.3
RUN SRC_DIR="/usr/local/src/protobuf-3.12.3" && \
    cd "${SRC_DIR}" && \
    apt-get update && \
    apt-get install -y autoconf automake libtool curl make g++ unzip && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc --all) && \
    make check && \
    eval 'checkinstall --default --nodoc --maintainer="Ryan Sinnet \<rsinnet@misorobotics.com\>" make install' && \
    mkdir -p /dist && \
    mv *.deb /dist && \
    ldconfig

CMD /bin/bash -c 'cp /dist/* /build'

# Install OSQP.
# RUN git clone --recursive https://github.com/oxfordcontrol/osqp.git \
#     && cd osqp/ \
#     && git checkout v0.6.2 \
#     && mkdir build \
#     && cd build \
#     && cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. \
#     && make "-j$(nproc)" \
#     && make install \
#     && cd ../../ \
#     && rm -rf osqp/

# Install latest cmake version
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2.tar.gz \
    && tar -zxvf cmake-3.20.2.tar.gz \
    && cd cmake-3.20.2 \
    && ls \
    && ./bootstrap \
    && make \
    && make -j6 \
    && make install \
    # && sudo apt-get install ros-kinetic-moveit ros-kinetic-uuid-msgs python-pip  && \
    # pip install xmltodict

Install git-prompt.
RUN GIT_VERSION="$(git version | cut -d' ' -f3 -)" \
    && wget -qO /etc/bash_completion.d/git-prompt.sh \
    https://raw.githubusercontent.com/git/git/v"${GIT_VERSION}"/contrib/completion/git-prompt.sh

# Add non-root user.
RUN adduser --disabled-password --gecos '' pinocchio
RUN chmod g+rw /home \
    && chown -R pinocchio:pinocchio /home/pinocchio
RUN usermod -aG plugdev,video,sudo pinocchio
USER pinocchio
WORKDIR /home/pinocchio/workspace

ENV PATH="/usr/local/bin${PATH:+:${PATH}}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
ENV LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}"
ENV CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
ENV DEBIAN_FRONTEND=

# Customize shell options.
RUN echo $'\
"\e[5~": history-search-backward\n\
"\e[6~": history-search-forward\n\
\n\
# Bash completion options.\n\
set colored-stats On\n\
set mark-symlinked-directories On\n\
set visible-stats On' \
    >> "${HOME}"/.inputrc

# Customize prompt.
RUN echo $'\n\
function _my_git_ps1 {\n\
  __git_ps1 "«$(tput setaf 213)$(tput bold)%s$(tput sgr0)» "\n\
}\n\
\n\
export GIT_PS1_SHOWCOLORHINTS=1\n\
export GIT_PS1_SHOWDIRTYSTATE=1\n\
\n\
DOCKER_PROMPT=\n\
if [[ $(grep -c docker /proc/1/cgroup) > 0 ]]; then\n\
  DOCKER_PROMPT=\'\[$(tput setaf 1)$(tput bold)\]docker\[$(tput sgr0)\]:\'\n\
fi\n\
\n\
export PS1=\\\n\
\'${debian_chroot:+($debian_chroot)}\'\\\n\
"${DOCKER_PROMPT}"\\\n\
\'\[$(tput setaf 2)\]\u\[$(tput sgr0)\]@\'\\\n\
\'\[$(tput setaf 3)\]\h\[$(tput sgr0)\] \'\\\n\
\'\[$(tput setaf 6)$(tput bold)\]\w\[$(tput sgr0)\] \'\\\n\
\'$(_my_git_ps1)\'' \
    >> "${HOME}"/.bashrc

# # Add openrobots install prefix.
# RUN echo $'\
# PATH="/opt/openrobots/bin:${PATH:+:${PATH}}"\n\
# PKG_CONFIG_PATH="/opt/openrobots/lib/pkgconfig:${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"\n\
# LD_LIBRARY_PATH="/opt/openrobots/lib:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"' \
#     >> "${HOME}"/.bashrc

USER root
# Add passwordless sudo.
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
    /etc/sudoers


ARG cachebust=1
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 555 /entrypoint.sh
COPY ./pinocchio.art /pinocchio.art
RUN chmod 444 /pinocchio.art
USER pinocchio
ENV ROS_DISTRO=${ROS_DISTRO}
ENTRYPOINT ["/entrypoint.sh"]
