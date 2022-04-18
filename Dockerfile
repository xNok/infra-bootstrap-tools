FROM ubuntu:focal

ARG TERRAFORM_VERSION="1.1.6"
ARG ANSIBLE_VERSION="2.10.7"
ARG PACKER_VERSION="1.5.4"

LABEL maintainer="xNok <nokwebspace@gmail.com>"
LABEL terraform_version=${TERRAFORM_VERSION}
LABEL ansible_version=${ANSIBLE_VERSION}
LABEL aws_cli_version=${AWSCLI_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=${AWSCLI_VERSION}
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV PACKER_VERSION=${PACKER_VERSION}

# Install apt packages and hashicorp products
RUN apt-get update \
    && apt-get install -y curl python3 python3-pip unzip  \
    && apt-get install -y openssh-client openssh-server sshpass \
    && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && curl -LO https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip '*.zip' -d /usr/local/bin \
    && rm *.zip

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ansible with pip plus require packages
RUN pip3 install -r requirement.txt

CMD    ["/bin/bash"]