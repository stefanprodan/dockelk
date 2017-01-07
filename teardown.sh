#!/bin/bash
set -e

docker-compose down -v --rmi all 

network="elk"
docker network rm $network