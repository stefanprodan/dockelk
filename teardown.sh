#!/bin/bash
set -e

docker-compose stop && docker-compose rm -f -v

network="elk"
docker network rm $network