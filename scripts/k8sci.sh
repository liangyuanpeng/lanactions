#!/bin/bash

set -o errexit;
set -o pipefail;
set -o nounset;

KIND_VERSION=${KIND_VERSION:-"v0.22.0"}
IMGTAG=${IMGTAG:-"v1.31.0-alpha.0"}

cat <<EOF> kind-ci.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  "AllAlpha": true
  "InTreePluginGCEUnregister": false
  "DisableCloudProviders": true
  "DisableKubeletCloudCredentialProviders": true
  "EventedPLEG": false
  "StorageVersionAPI": false
  "UnknownVersionInteroperabilityProxy": false # 必须要StorageVersionAPI开启
networking:
  ipFamily: ipv4
nodes:
- role: control-plane
  image: ghcr.io/liangyuanpeng/kindest/testnode:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: application/json
- role: worker
  image: ghcr.io/liangyuanpeng/kindest/testnode:$KIND_VERSION-$IMGTAG
- role: worker
  image: ghcr.io/liangyuanpeng/kindest/testnode:$KIND_VERSION-$IMGTAG
EOF

cat kind-ci.yaml

/usr/local/bin/kind create cluster \
--name kind           \
-v7 --wait 4m --retain --config=kind-ci.yaml

mkdir _artifacts
cp ~/.kube/config _artifacts/
mkdir -p _artifacts/testreport