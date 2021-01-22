FROM ubuntu:focal

ARG TERRAFORM_VERSION="0.12.23"
# TODO: currnet ubuntu ansible version 2.5.1 update to use variable
# TODO: reduce size of image is pip or binary tarball better
ARG ANSIBLE_VERSION="2.9.1"
ARG PACKER_VERSION="1.5.4"
ARG AWSCLI_VERSION="1.18.19"

LABEL maintainer="Codebarber <ernest@codebarber.com>"
LABEL terraform_version=${TERRAFORM_VERSION}
LABEL ansible_version=${ANSIBLE_VERSION}
LABEL aws_cli_version=${AWSCLI_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=${AWSCLI_VERSION}
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV PACKER_VERSION=${PACKER_VERSION}
RUN apt-get update \
    && apt-get install -y ansible curl python3 python3-pip python3-boto unzip  \
    && pip3 install --upgrade awscli==${AWSCLI_VERSION} \
    && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && curl -LO https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip '*.zip' -d /usr/local/bin \
    && rm *.zip

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip3 install jsondiff pyyaml passlib

CMD    ["/bin/bash"]

RUN apt-get update \
     && apt-get install -y openssh-client openssh-server sshpass