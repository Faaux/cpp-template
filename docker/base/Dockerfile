ARG DISTRO_VERSION

FROM ubuntu:${DISTRO_VERSION}

ENV PYENV_ROOT=/opt/pyenv \
    PATH=/opt/pyenv/shims:/opt/conan/binutils/bin:${PATH} \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"

WORKDIR /root

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends --no-install-suggests -o=Dpkg::Use-Pty=0 \
       sudo \
       binutils \
       wget \
       git \
       g++-multilib \
       libgmp-dev \
       libmpfr-dev \
       libmpc-dev \
       nasm \
       dh-autoreconf \
       libffi-dev \
       libssl-dev \
       pkg-config \
       zlib1g-dev \
       libbz2-dev \
       libsqlite3-dev \
       libreadline-dev \
       xz-utils \
       curl \
       libncurses5-dev \
       libncursesw5-dev \
       liblzma-dev \
       ca-certificates \
       autoconf-archive \
       language-pack-en \
       make \
       unzip \
       python3 \
       sudo \
       openssh-server \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q --no-check-certificate https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-linux.zip \
    && unzip ninja-linux.zip \
    && mv ninja /usr/bin/ninja

ARG CMAKE_VERSION

RUN wget -q --no-check-certificate https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    && tar -xzf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
       --exclude=bin/cmake-gui \
       --exclude=doc/cmake \
       --exclude=share/cmake-${CMAKE_VERSION%.*}/Help \
       --exclude=share/vim \
       --exclude=share/vim \
    && cp -fR cmake-${CMAKE_VERSION}-linux-x86_64/* /usr \
    && rm -rf /root/cmake-${CMAKE_VERSION}-linux-x86_64 \
    && rm /root/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz

RUN printf '/usr/local/lib\n' > /etc/ld.so.conf.d/20local-lib.conf \
    && printf '/usr/local/lib64\n' >> /etc/ld.so.conf.d/20local-lib.conf \
    && mv /etc/ld.so.conf.d/libc.conf /etc/ld.so.conf.d/10libc.conf \
    && rm /etc/ld.so.cache \
    && ldconfig -C /etc/ld.so.cache \
    && apt-get -qq purge -y \
       g++-multilib \
       gcc \
       libgmp-dev \
       libmpfr-dev \
       libmpc-dev \
       libffi-dev \
       libssl-dev \
       zlib1g-dev \
       libbz2-dev \
       libsqlite3-dev \
       libreadline-dev \
       libncurses5-dev \
       libncursesw5-dev \
       liblzma-dev \
    && apt-get -qq autoremove -y \
    && apt-get -qq autoclean \
    && apt-get -qq update \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

ARG USERNAME=bob
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Setup SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && service ssh start

EXPOSE 22

# Create the user
RUN userdel -r ubuntu \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --create-home --uid $USER_UID --gid $USER_GID --shell /bin/bash -m $USERNAME \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["sudo", "/usr/sbin/sshd", "-D"]
