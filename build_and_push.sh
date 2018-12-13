#!/bin/bash
set -e

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
./generate-stackbrew-library.sh > server
bashbrew --config .bashbrew/ --library ./ build server
bashbrew --config .bashbrew/ --library ./ push server
