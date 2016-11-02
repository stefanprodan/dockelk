#!/bin/bash
set -e

hostIP="$(hostname -I|awk '{print $1}')"

network="elk"

# create network
if [ ! "$(docker network ls --filter name=$network -q)" ];then
    docker network create --subnet=192.16.0.0/24 $network
fi

docker-compose pull
docker-compose up -d --force-recreate --build
