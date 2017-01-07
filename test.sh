#!/bin/bash
set -e

hostIP="$(hostname -I|awk '{print $1}')"

docker run -dp 80:80 --name nginx --log-driver=gelf --log-opt gelf-address=udp://${hostIP}:12201 nginx

# generate nginx logs
curl -s http://hostIP
curl -s http://hostIP/404


