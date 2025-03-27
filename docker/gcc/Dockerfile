ARG DOCKER_USERNAME
ARG DOCKER_TAG
ARG DISTRO
ARG SUFFIX

FROM ${DOCKER_USERNAME}/base-${DISTRO}${SUFFIX}:${DOCKER_TAG} AS deploy

ARG GCC_VERSION

RUN sudo add-apt-repository ppa:ubuntu-toolchain-r/ppa -y \
    && sudo apt-get update \
    && sudo apt-get -qq install -y --no-install-recommends g++-14 gcc-14 \
    && sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 10 \
    && sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 10 \
    && sudo update-alternatives --install /usr/local/bin/cc cc /usr/bin/gcc-14 10 \
    && sudo update-alternatives --install /usr/local/bin/c++ c++ /usr/bin/g++-14 10
