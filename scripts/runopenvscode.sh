#!/bin/bash

wget https://github.com/gitpod-io/openvscode-server/releases/download/openvscode-server-v1.73.1/openvscode-server-v1.73.1-linux-x64.tar.gz
tar -xf openvscode-server-v1.73.1-linux-x64.tar.gz
rm -f openvscode-server-v1.73.1-linux-x64.tar.gz
openvscode-server-v1.73.1-linux-x64/bin/openvscode-server --port 3001 --host 0.0.0.0 --without-connection-token
