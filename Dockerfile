ARG UBUNTU_VERSION=18.04
FROM nvidia/cudagl:11.2.2-base-ubuntu${UBUNTU_VERSION}
ARG ROS_DISTRO=melodic
SHELL ["/bin/bash", "-c"]
WORKDIR /root/

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

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

RUN add-apt-repository ppa:git-core/ppa \
    && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y --no-install-recommends \
    bash-completion git git-lfs tig vim \
    gdb valgrind \
    python-{ipython,matplotlib,numpy,pudb,pytest,scipy} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/cache

RUN GIT_VERSION="$(git version | cut -d' ' -f3 -)" \
    && wget -qO /etc/bash_completion.d/git-prompt.sh \
    https://raw.githubusercontent.com/git/git/v"${GIT_VERSION}"/contrib/completion/git-prompt.sh

RUN adduser --disabled-password --gecos '' pinocchio
RUN chmod g+rw /home && \
    chown -R pinocchio:pinocchio /home/pinocchio
USER pinocchio
WORKDIR /home/pinocchio/workspace

ENV PATH="/usr/local/bin${PATH:+:${PATH}}"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
ENV LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}"
ENV CMAKE_PREFIX_PATH="/usr/local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
ENV DEBIAN_FRONTEND=

RUN echo $'\
"\e[5~": history-search-backward\n\
"\e[6~": history-search-forward\n\
\n\
# Bash completion options.\n\
set colored-stats On\n\
set mark-symlinked-directories On\n\
set visible-stats On' \
>> "${HOME}"/.inputrc

RUN echo $'\
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

USER root
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 555 /entrypoint.sh
COPY ./pinocchio.art /pinocchio.art
RUN chmod 444 /pinocchio.art
USER pinocchio
ENV ROS_DISTRO=${ROS_DISTRO}
ENTRYPOINT ["/entrypoint.sh"]
