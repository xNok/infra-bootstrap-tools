
if [ -z "$INFRA_IMAGE_NAME" ]; then
  INFRA_IMAGE_NAME="local-infra-tools"
  docker build -t $INFRA_IMAGE_NAME .
  echo -e "build image \e[36m$INFRA_IMAGE_NAME\e[0m"
fi

echo -e "use \e[36mdasb\e[0m for \e[36mansible\e[0m in docker"

dasb () 
{
  docker run --rm \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME ansible $@
}

echo -e "use \e[36mdap\e[0m for \e[36mansible-playbook\e[0m in docker"

dap () 
{
  docker run --rm -it \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME ansible-playbook $@
}

echo -e "use \e[36mdaws\e[0m for \e[36mawscli\e[0m in docker"

daws () 
{
  docker run --rm \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME aws $@
}

echo -e "use \e[36mdpk\e[0m for \e[36mpacker\e[0m in docker"

dpk () 
{
  docker run --rm \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME packer $@
}

echo -e "use \e[36mdtf\e[0m for \e[36mterraform\e[0m in docker"

dtf () 
{
  docker run --rm \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME terraform $@
}

echo -e "use \e[36mdbash\e[0m for \e[36mbash\e[0m in docker"

dbash () 
{
  docker run --rm -it \
             -w /opt \
             -v $(pwd):/opt/ \
             -v ~/.aws:/root/.aws \
             -v ~/.ssh:/root/.ssh \
             $INFRA_IMAGE_NAME bash
}