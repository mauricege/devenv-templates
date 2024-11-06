FROM nvcr.io/nvidia/cuda-dl-base:24.10-cuda12.6-devel-ubuntu22.04


RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --no-confirm --init none

RUN curl -sfL https://direnv.net/install.sh | bash

WORKDIR /nix-environment

COPY .envrc pyproject.toml uv.lock ./

COPY .nix ./.nix

RUN direnv allow . && echo "$(direnv export bash)" >> .bashrc

WORKDIR /src

ENTRYPOINT [ "bash", "--rcfile", "/nix-environment/.bashrc" ]
