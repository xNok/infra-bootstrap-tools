FROM codebarber/ansible-packer-terraform

RUN apt-get update \
     && apt-get install -y openssh-client openssh-server sshpass