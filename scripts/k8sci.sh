#!/bin/bash

set -o errexit;
set -o pipefail;
set -o nounset;


function util::deployk8s(){
  STEP_WAHT=${STEP_WAHT:-""}
   # deployk8s, runtests
  if [ $STEP_WAHT = "deployk8s" ];then 
    KIND_VERSION=${KIND_VERSION:-"v0.22.0"}
    IMGTAG=${IMGTAG:-"v1.31.0-alpha.0"}
    STORAGE_MEDIA_TYPE=${STORAGE_MEDIA_TYPE:-"json"}

    REALLY_STORAGE_MEDIA_TYPE=${REALLY_STORAGE_MEDIA_TYPE:-"application/json"}

    if [ $STORAGE_MEDIA_TYPE = "json" ];then 
      REALLY_STORAGE_MEDIA_TYPE="application/json"
    fi

    if [ $STORAGE_MEDIA_TYPE = "protobuf" ];then 
      REALLY_STORAGE_MEDIA_TYPE="application/vnd.kubernetes.protobuf"
    fi

    if [ $STORAGE_MEDIA_TYPE = "yaml" ];then 
      REALLY_STORAGE_MEDIA_TYPE="application/yaml"
    fi

    if [ $STORAGE_MEDIA_TYPE = "cbor" ];then 
      REALLY_STORAGE_MEDIA_TYPE="application/vnd.kubernetes.protobuf"
    fi

    # application/vnd.kubernetes.protobuf
    # application/json

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
            storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
    - role: worker
      image: ghcr.io/liangyuanpeng/kindest/testnode:$KIND_VERSION-$IMGTAG
    - role: worker
      image: ghcr.io/liangyuanpeng/kindest/testnode:$KIND_VERSION-$IMGTAG
    EOF

    cat kind-ci.yaml

    /usr/local/bin/kind create cluster \
    --name kind           \
    -v7 --wait 4m --retain --config=kind-ci.yaml

    mkdir -p _artifacts
    cp ~/.kube/config _artifacts/
    mkdir -p _artifacts/testreport
  fi
}

function util::runtests(){
  STEP_WAHT=${STEP_WAHT:-""}
  TESTS_WITH=${TESTS_WITH:-"ginkgo"}
  # ginkgo hydrophone
  TEST_WHAT=${TEST_WHAT:-"conformance"}
  if [ $STEP_WAHT = "runtests" ];then
    if [ $TEST_WHAT = "conformance" ];then
      ginkgo --nodes=25                \
          --focus="\[Conformance\]"     \
          --skip="Feature|Federation|machinery|PerformanceDNS|DualStack|Disruptive|Serial|Slow|KubeProxy|LoadBalancer|GCE|Netpol|NetworkPolicy|NodeConformance"   \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=false
    fi

    if [ $TEST_WHAT = "statefulset" ];then
      ginkgo --nodes=25                \
          --focus="\[Feature:StatefulSet\]"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=false
    fi
  fi
}

util::deployk8s
util::runtests
