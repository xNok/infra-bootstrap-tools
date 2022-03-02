#!/bin/bash

build ()
{
    docker build -t toolchain .
}

drun () 
{
  docker run --rm -it \
            -w /home/ubuntu \
            -v $(pwd):/home/ubuntu \
            "toolchain"
}