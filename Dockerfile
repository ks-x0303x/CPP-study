FROM ubuntu:22.04

ENV HOME=/home/ubuntu
ENV CXX=g++
WORKDIR /home/ubuntu/Shared
COPY ./Shared /home/ubuntu/Shared
COPY ./requirements.txt /home/ubuntu/requirements.txt

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    vim \
    build-essential \
    gcc \
    g++ \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    gcc-x86-64-linux-gnu \
    g++-x86-64-linux-gnu \
    binutils-x86-64-linux-gnu \
    gdb-multiarch \
    gdbserver \
    cmake \
    python3 \
    python3-pip \
    wget \
    curl \
    git \
    meson \
    rpm \
    rpm2cpio \
    cpio \
    pkg-config \
    libboost-all-dev \
        libgtest-dev \
        libgmock-dev \
    ninja-build && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# GoogleTest (Ubuntuではヘッダ/ソースのみの場合があるため、確実にリンクできるようビルドしてインストール)
RUN set -eux; \
        if [ -d /usr/src/googletest ]; then src_dir=/usr/src/googletest; \
        elif [ -d /usr/src/gtest ]; then src_dir=/usr/src/gtest; \
        else echo "googletest source dir not found under /usr/src"; exit 1; fi; \
        cmake -S "${src_dir}" -B /tmp/googletest-build \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON; \
        cmake --build /tmp/googletest-build -j"$(nproc)"; \
        cmake --install /tmp/googletest-build; \
        rm -rf /tmp/googletest-build

# Boost 1.74 (Ubuntu 22.04 のパッケージ) は apt で導入する

# Go言語のインストール (実行環境のCPUに追従)
ENV GO_VERSION=1.20.5
RUN set -eu; \
    dpkg_arch="$(dpkg --print-architecture)"; \
    case "${dpkg_arch}" in \
        amd64) go_arch="amd64" ;; \
        arm64) go_arch="arm64" ;; \
        *) echo "Unsupported architecture: ${dpkg_arch}"; exit 1 ;; \
    esac; \
    wget "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" && \
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-${go_arch}.tar.gz" && \
    rm "go${GO_VERSION}.linux-${go_arch}.tar.gz"

# Goの環境変数を設定
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# PIP install
RUN pip install -r /home/ubuntu/requirements.txt -q --no-warn-script-location

# SSHの設定
RUN mkdir /var/run/sshd
RUN echo 'root:rootpassword' | chpasswd

# SSHを許可するために公開鍵認証を無効にし、パスワード認証を有効化
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# sudo権限を設定
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSHデーモン起動用のポートを開放
EXPOSE 22

# コンテナ起動時にSSHサービスを開始する
CMD ["/usr/sbin/sshd", "-D"]