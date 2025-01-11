# ベースイメージにUbuntuを使用 (ARM64対応)
FROM ubuntu:22.04

COPY ./Shared /home/ubuntu/Shared

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    vim \
    build-essential \
    gcc \
    g++ \
    gdb-multiarch \
    cmake \
    python3 \
    python3-pip \
    wget \
    curl \
    git \
    meson \
    ninja-build && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Boost 1.74のインストール
RUN cd /home/ubuntu/Shared/external && \
    tar -xvzf boost_1_74_0.tar.gz && \
    cd boost_1_74_0 && \
    ./bootstrap.sh && \
    ./b2 install && \
    cd .. && \
    rm -rf boost_1_74_0 boost_1_74_0.tar.gz

# Go言語のインストール (aarch64対応)
ENV GO_VERSION=1.20.5
RUN wget https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-arm64.tar.gz && \
    rm go$GO_VERSION.linux-arm64.tar.gz

# Goの環境変数を設定
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

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