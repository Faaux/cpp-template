ARG DISTRO_VERSION=24.04

FROM ubuntu:${DISTRO_VERSION}

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# We ignore this because we can not set specific version for each apt packages
# hadolint ignore=DL3008
RUN apt-get update -qq && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        software-properties-common wget apt-utils file zip unzip \
        openssh-server gpg-agent gnupg apt-transport-https socat rsync \
        make git \
        pkg-config curl \
        python3 python3-pip sudo \
        neovim emacs nano \
        doxygen graphviz sccache \
        gdb lld \
        autoconf libtool && \
    rm -rf /var/lib/apt/lists/*

# Ninja
ARG NINJA_VERSION=1.12.1

RUN wget -q --no-check-certificate https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip \
    && unzip ninja-linux.zip \
    && mv ninja /usr/bin/ninja

# CMake
ARG CMAKE_VERSION=3.31.6

RUN wget -q --no-check-certificate https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    && tar -xzf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
       --exclude=bin/cmake-gui \
       --exclude=doc/cmake \
       --exclude=share/cmake-${CMAKE_VERSION%.*}/Help \
       --exclude=share/vim \
       --exclude=share/vim \
    && cp -fR cmake-${CMAKE_VERSION}-linux-x86_64/* /usr \
    && rm -rf cmake-${CMAKE_VERSION}-linux-x86_64 \
    && rm cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz

# GCC
ARG GCC_VERSION=14

# hadolint ignore=DL3008
RUN add-apt-repository ppa:ubuntu-toolchain-r/ppa -y \
    && apt-get update -qq \
    && apt-get -qq install -y --no-install-recommends g++-${GCC_VERSION} gcc-${GCC_VERSION} gcc-${GCC_VERSION}-multilib  \
    && update-alternatives --install /usr/bin/gcc gcc "$(which gcc-${GCC_VERSION})" 100 \
    && update-alternatives --install /usr/bin/g++ g++ "$(which g++-${GCC_VERSION})" 100 \
    && rm -rf /var/lib/apt/lists/*


# CLANG
ARG CLANG_VERSION=19

RUN wget -q --no-check-certificate https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 19 all

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100 \
    && update-alternatives --install /usr/local/bin/ld ld "$(which ld.lld-${CLANG_VERSION})" 100 \
    && update-alternatives --install /usr/local/bin/cc cc "$(which clang-${CLANG_VERSION})" 100 \
    && update-alternatives --install /usr/local/bin/c++ c++ "$(which clang++-${CLANG_VERSION})" 100

# Mold Linker
ARG MOLD_VERSION=2.38.1

RUN wget -q --no-check-certificate https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz \
    && tar -xzf mold-${MOLD_VERSION}-x86_64-linux.tar.gz \
       --strip-components 1 \
       -C /usr/local \
    && update-alternatives --install /usr/local/bin/ld ld "$(which mold)" 101 \
    && rm mold-${MOLD_VERSION}-x86_64-linux.tar.gz

# IWYU
ENV IWYU /home/iwyu
ENV IWYU_BUILD ${IWYU}/build
ENV IWYU_SRC ${IWYU}/include-what-you-use
RUN mkdir -p ${IWYU_BUILD} && \
    git clone --branch clang_${CLANG_VERSION} \
        https://github.com/include-what-you-use/include-what-you-use.git \
        ${IWYU_SRC}
RUN CC=clang-${CLANG_VERSION} CXX=clang++-${CLANG_VERSION} cmake -S ${IWYU_SRC} \
        -B ${IWYU_BUILD} \
        -G "Unix Makefiles" -DCMAKE_PREFIX_PATH=/usr/lib/llvm-${CLANG_VERSION} && \
    cmake --build ${IWYU_BUILD} -j && \
    cmake --install ${IWYU_BUILD}

# Setup SSH and User
ARG USERNAME=bob
ARG USER_UID=1000
ARG USER_GID=$USER_UID

## Cleanup cached apt data we don't need anymore
RUN apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

# UV -> pre-commit
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && source $HOME/.local/bin/env \
    && uv tool install pre-commit

# Run SSH by default if run manually
CMD ["sudo", "/usr/sbin/sshd", "-D"]
