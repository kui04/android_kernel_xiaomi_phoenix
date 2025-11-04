# From https://github.com/ravindu644/Android-Kernel-Tutorials/blob/main/docker/full/Dockerfile
# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV KBUILD_BUILD_USER="@kui04"

# Install all required packages
RUN apt-get update && apt-get install -y \
    # scripts/dtc/libfdt/mkdtboimg.py still require Python 2    
    python2 \
    android-sdk-libsparse-utils \
    bash-completion \
    bc \
    tmux \
    bison \
    build-essential \
    bzip2 \
    neofetch \
    coreutils \
    cpio \
    curl \
    rsync \
    default-jdk \
    device-tree-compiler \
    e2fsprogs \
    erofs-utils \
    f2fs-tools \
    file \
    findutils \
    flex \
    g++ \
    gcc \
    git \
    gnupg \
    gperf \
    grep \
    htop \
    iproute2 \
    iputils-ping \
    kmod \
    libarchive-tools \
    libc6-dev \
    libelf-dev \
    libgl1 \
    libgl1-mesa-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    libx11-dev \
    libxml2-utils \
    lz4 \
    make \
    nano \
    net-tools \
    openssl \
    openjdk-17-jdk \
    p7zip-full \
    pahole \
    procps \
    python-is-python3 \
    python3 \
    python3-markdown \
    python3-pip \
    repo \
    sudo \
    tar \
    tofrodos \
    unzip \
    tree \
    util-linux \
    vim \
    wget \
    xsltproc \
    xz-utils \
    zip \
    zlib1g-dev \
    zstd \
    --fix-missing && \
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb && \
    dpkg -i libtinfo5_6.3-2ubuntu0.1_amd64.deb && \
    rm libtinfo5_6.3-2ubuntu0.1_amd64.deb && \
    apt-get full-upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the user and set up passwordless sudo
RUN useradd -m -s /bin/bash kernel-builder && \
    echo "kernel-builder:kernel-builder" | chpasswd && \
    adduser kernel-builder sudo && \
    echo "kernel-builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kernel-builder

# Set the working directory to the kernel-builder's home
WORKDIR /home/kernel-builder

# Set the default user to "kernel-builder"
USER kernel-builder

# Init arm gnu toolchain
RUN mkdir -p "/home/kernel-builder/toolchains/gcc" && \
    cd "/home/kernel-builder/toolchains/gcc" && \
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz" && \
    tar -xf arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz && \
    rm arm-gnu-toolchain-13.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz

# Init arm gnu toolchain
RUN mkdir -p "/home/kernel-builder/toolchains/gcc" && \
    cd "/home/kernel-builder/toolchains/gcc" && \
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz" && \
    tar -xf arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz && \
    rm arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz

# Init clang-r510928
RUN mkdir -p "/home/kernel-builder/toolchains/clang-r510928" && \
    cd "/home/kernel-builder/toolchains/clang-r510928" && \
    curl -LO "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/android-14.0.0_r33/clang-r510928.tar.gz" && \
    tar -xf clang-r510928.tar.gz && \
    rm clang-r510928.tar.gz

# Final command to keep the container running
CMD ["bash"]