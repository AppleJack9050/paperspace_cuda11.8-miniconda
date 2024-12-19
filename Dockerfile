#!/bin/bash

# Paperspace Dockerfile for Gradient base image
# Paperspace image is located in Dockerhub registry: paperspace/gradient_base

# ==================================================================
# Initial setup
# ------------------------------------------------------------------

    # Ubuntu 22.04 as base image
    FROM ubuntu:22.04
    RUN yes| unminimize

    # Set ENV variables
    ENV LANG C.UTF-8
    ENV SHELL=/bin/bash
    ENV DEBIAN_FRONTEND=noninteractive

    ENV APT_INSTALL="apt-get install -y --no-install-recommends"
    ENV PIP_INSTALL="pip --no-cache-dir install --upgrade"
    ENV GIT_CLONE="git clone --depth 10"


# ==================================================================
# Tools
# ------------------------------------------------------------------

    RUN apt-get update && \
        $APT_INSTALL \
        gcc \
        make \
        pkg-config \
        apt-transport-https \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        rsync \
        git \
        vim \
        mlocate \
        libssl-dev \
        curl \
        openssh-client \
        unzip \
        unrar \
        zip \
        awscli \
        csvkit \
        emacs \
        joe \
        jq \
        dialog \
        man-db \
        manpages \
        manpages-dev \
        manpages-posix \
        manpages-posix-dev \
        nano \
        iputils-ping \
        sudo \
        ffmpeg \
        libsm6 \
        libxext6 \
        libboost-all-dev \
        gnupg \
        cifs-utils \
        zlib1g \
        software-properties-common

# ==================================================================
# Git-lfs
# ------------------------------------------------------------------
    
    RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
        $APT_INSTALL git-lfs


# ==================================================================
# Python
# ------------------------------------------------------------------

    #Based on https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa

    # Adding repository for python3.11
    RUN add-apt-repository ppa:deadsnakes/ppa -y && \
        $APT_INSTALL \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        python3-distutils-extra

    # Add symlink so python and python3 commands use same python3.9 executable
    RUN ln -s /usr/bin/python3.11 /usr/local/bin/python3 && \
        ln -s /usr/bin/python3.11 /usr/local/bin/python    

    # Installing pip
    RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3
    ENV PATH=$PATH:/root/.local/bin    

# ==================================================================
# Installing CUDA packages (CUDA Toolkit 11.8 and CUDNN 9.6)
# ------------------------------------------------------------------
    RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin && \
        mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
        wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb && \
        dpkg -i cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb && \
        cp /var/cuda-repo-ubuntu2204-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
        apt-get update && \
        $APT_INSTALL cuda && \
        rm cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb

    RUN wget https://developer.download.nvidia.com/compute/cudnn/9.6.0/local_installers/cudnn-local-repo-ubuntu2204-9.6.0_1.0-1_amd64.deb && \
        dpkg -i cudnn-local-repo-ubuntu2204-9.6.0_1.0-1_amd64.deb && \
        cp /var/cudnn-local-repo-ubuntu2204-9.6.0/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
        apt-get update && \
        $APT_INSTALL cudnn-cuda-11

    ENV PATH=$PATH:/usr/local/cuda/bin
    ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# ==================================================================
# Install Minicoda
# ------------------------------------------------------------------
# Install Miniconda
    ENV CONDA_DIR=/opt/conda
    ENV PATH=$CONDA_DIR/bin:$PATH

    RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
        mkdir -p $CONDA_DIR && \
        bash Miniconda3-latest-Linux-x86_64.sh -b -f -p $CONDA_DIR && \
        rm Miniconda3-latest-Linux-x86_64.sh

    RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
        echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
        echo "conda activate base" >> ~/.bashrc && \
        find /opt/conda/ -follow -type f -name '*.a' -delete && \
        find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
        /opt/conda/bin/conda clean -afy

# ==================================================================
# PyTorch
# ------------------------------------------------------------------

    # Based on https://pytorch.org/get-started/locally/

    RUN $PIP_INSTALL torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# ==================================================================
# TensorFlow
# ------------------------------------------------------------------

    # Based on https://www.tensorflow.org/install/pip

    RUN $PIP_INSTALL tensorflow

# ==================================================================
# JupyterLab
# ------------------------------------------------------------------

    # Based on https://jupyterlab.readthedocs.io/en/stable/getting_started/installation.html#pip

    RUN $PIP_INSTALL jupyter -U && pip install jupyterlab

    # ==================================================================
# Installing JRE and JDK
# ------------------------------------------------------------------

    RUN $APT_INSTALL \
        default-jre \
        default-jdk


# ==================================================================
# CMake
# ------------------------------------------------------------------

    RUN $GIT_CLONE https://github.com/Kitware/CMake ~/cmake && \
        cd ~/cmake && \
        ./bootstrap && \
        make -j"$(nproc)" install

# ==================================================================
# Startup
# ------------------------------------------------------------------

    EXPOSE 8888 6006

    CMD jupyter lab --allow-root --ip=0.0.0.0 --no-browser --ServerApp.trust_xheaders=True --ServerApp.disable_check_xsrf=False --ServerApp.allow_remote_access=True --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True