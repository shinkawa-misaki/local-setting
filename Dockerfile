FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    sudo \
    zsh \
    vim \
    wget \
    build-essential \
    software-properties-common \
    sed \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /bin/sed /usr/local/bin/gsed

RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/testuser

USER testuser

COPY --chown=testuser:testuser . /home/testuser/local-setting/
CMD ["/bin/bash"]
