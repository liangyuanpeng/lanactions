#!/bin/bash

set -o errexit;
set -o pipefail;
set -o nounset;

# kind create cluster --image ghcr.io/liangyuanpeng/kindest/testnode:v0.22.0-v1.31.0-alpha.0-368-g47ad87e95fe
function util::deployk8s(){
  STEP_WHAT=${STEP_WHAT:-"none"}
   # deployk8s, runtests
  if [ $STEP_WHAT = "deployk8s" ];then 
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
  "AllBeta": true
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

# Summarizing 3 Failures:
#   [FAIL] [sig-apps] StatefulSet Deploy clustered applications [Feature:StatefulSet] [Slow] [It] should creating a working redis cluster [sig-apps, Feature:StatefulSet, Slow]
#   k8s.io/kubernetes/test/e2e/framework/statefulset/rest.go:69
#   [FAIL] [sig-apps] StatefulSet Deploy clustered applications [Feature:StatefulSet] [Slow] [It] should creating a working mysql cluster [sig-apps, Feature:StatefulSet, Slow]
#   k8s.io/kubernetes/test/e2e/framework/statefulset/rest.go:69
#   [FAIL] [sig-apps] StatefulSet Deploy clustered applications [Feature:StatefulSet] [Slow] [It] should creating a working zookeeper cluster [sig-apps, Feature:StatefulSet, Slow]
#   k8s.io/kubernetes/test/e2e/framework/statefulset/rest.go:69

function util::runtests(){
  STEP_WHAT=${STEP_WHAT:-"none"}
  TESTS_WITH=${TESTS_WITH:-"ginkgo"}
  # ginkgo hydrophone
  TEST_WHAT=${TEST_WHAT:-"none"}
  if [ $STEP_WHAT = "runtests" ];then
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

    # [StatefulSetBasic]
    # StatefulSetStartOrdinal 
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

    if [ $TEST_WHAT = "sig-apps" ];then
      ginkgo --nodes=25                \
          --focus="\[sig-apps\]|\[sig-api-machinery\]"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=false
    fi

    if [ $TEST_WHAT = "kind-e2e" ];then
      export FOCUS=.
      
      curl -sSL https://kind.sigs.k8s.io/dl/latest/linux-amd64.tgz | tar xvfz - -C "${PATH%%:*}/" && e2e-k8s.sh
    fi

  fi
}

util::deployk8s
util::runtests
