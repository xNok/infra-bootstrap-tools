#!/bin/bash

if [ -z "$INFRA_IMAGE_NAME" ]; then
  INFRA_IMAGE_NAME="local-infra-tools"
  docker build -t $INFRA_IMAGE_NAME .
  echo -e "build image \e[36m$INFRA_IMAGE_NAME\e[0m"
fi

drun () 
{
  docker run --rm "${TTY}" \
            -w /home/ubuntu \
            -v "$(pwd)":/home/ubuntu \
            -v ~/.ssh:/home/ubuntu/.ssh \
            -v ~/.aws:/home/ubuntu/.aws \
            -e AWS_PROFILE \
            "$INFRA_IMAGE_NAME" "$@"
}

echo -e "use \e[36mdasb\e[0m for \e[36mansible\e[0m in docker"

dasb () 
{
  drun ansible "$@"
}

echo -e "use \e[36mdap\e[0m for \e[36mansible-playbook\e[0m in docker"

dap () 
{
  drun ansible-playbook "$@"
}

echo -e "use \e[36mdaws\e[0m for \e[36mawscli\e[0m in docker"

daws () 
{
  drun aws "$@"
}

echo -e "use \e[36mdpk\e[0m for \e[36mpacker\e[0m in docker"

dpk () 
{
  drun packer "$@"
}

echo -e "use \e[36mdtf\e[0m for \e[36mterraform\e[0m in docker"

dtf () 
{
  drun terraform "$@"
}

echo -e "use \e[36mdbash\e[0m for \e[36mbash\e[0m in docker"

dbash () 
{
  TTY="-it"
  drun bash "$@"
  unset TTY
}