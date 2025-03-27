ARG DOCKER_USERNAME
ARG DOCKERHUB_USERNAME
ARG DOCKER_TAG
ARG DISTRO_VERSION
ARG DISTRO
ARG SUFFIX

FROM ${DOCKER_USERNAME}/gcc-${DISTRO}:latest AS deploy

ARG LIBSTDCPP_VERSION
ARG LIBSTDCPP_PATCH_VERSION

RUN sudo apt-get -qq update \
    && sudo apt-get -qq install -y --no-install-recommends --no-install-suggests -o=Dpkg::Use-Pty=0 \
       apt-transport-https \
       gnupg

RUN wget -q --no-check-certificate https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && sudo ./llvm.sh 19 all

RUN sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 10 \
    && sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 10 \
    && sudo update-alternatives --install /usr/local/bin/cc cc /usr/bin/clang-19 20 \
    && sudo update-alternatives --install /usr/local/bin/c++ c++ /usr/bin/clang++-19 20 \
    && sudo update-alternatives --install /usr/local/bin/ld ld /usr/bin/ld.lld-19 20 \
    && sudo rm /etc/ld.so.cache \
    && sudo ldconfig -C /etc/ld.so.cache
