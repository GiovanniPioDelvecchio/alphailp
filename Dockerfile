FROM nvidia/cuda:12.8.0-devel-ubuntu24.04
LABEL maintainer="nesy-course"

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /aILP
ENV TORCH_CUDA_ARCH_LIST="12.0"

RUN apt-get update -y && \
    apt-get install -y curl git bash nano wget \
                       python3.12 python3-pip python3.12-venv && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip

# Fonts/rendering deps carried over from the original Dockerfile --
# needed for LaTeX-style serif rendering in matplotlib figures
RUN apt-get update && \
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    apt-get install --yes ttf-mscorefonts-installer && \
    ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get install --yes dvipng cm-super fonts-cmu fonts-dejavu-core && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

# PyTorch with CUDA 12.8 for RTX 5090 (sm_120) -- must be 2.7.0+, matches
# what we used for the Factify container; installed AFTER requirements.txt
# so it isn't silently overridden by an unpinned torch line in there
RUN pip install --no-cache-dir \
    torch==2.7.1+cu128 \
    torchvision==0.22.1+cu128 \
    torchaudio==2.7.1+cu128 \
    --index-url https://download.pytorch.org/whl/cu128