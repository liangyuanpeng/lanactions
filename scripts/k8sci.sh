#!/bin/bash

set -o errexit;
set -o pipefail;
set -o nounset;

function util::getbuild(){
  STEP_WHAT=${STEP_WHAT:-"none"}
  KIND_VERSION=${KIND_VERSION:-"v0.22.0"}
  if [ $STEP_WHAT = "getbuild" ];then 
    wget -q https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64
    chmod +x kind-linux-amd64 &&  mv kind-linux-amd64 /usr/local/bin/kind
  fi
}

# kind create cluster --image $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:v0.22.0-v1.31.0-alpha.0-368-g47ad87e95fe
function util::deployk8s(){
  STEP_WHAT=${STEP_WHAT:-"none"}
   # deployk8s, runtests
  if [ $STEP_WHAT = "deployk8s" ];then 
    KIND_VERSION=${KIND_VERSION:-"v0.22.0"}
    IMGTAG=${IMGTAG:-"v1.31.0-alpha.0"}
    STORAGE_MEDIA_TYPE=${STORAGE_MEDIA_TYPE:-"json"}
    KIND_IMG_REPO=${KIND_IMG_REPO:-"kindest/testnode"}
    KIND_IMG_REGISTRY=${KIND_IMG_REGISTRY:-"ghcr.io"}
    KIND_IMG_USER=${KIND_IMG_USER:-"liangyuanpeng"}
    # k8s master 节点数量,  1master2node  3master2node
    K8S_CP_COUNT=${K8S_CP_COUNT:-"1"}
    WHICH_ETCD=${WHICH_ETCD:-"build-in"}

    if [ $WHICH_ETCD = "xline" ];then 
      echo "docker run xline"
    fi

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

    if [ $K8S_CP_COUNT = "1" ];then

      if [ $WHICH_ETCD = "build-in" ];then

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
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
EOF
      fi
      if [ $WHICH_ETCD = "xline" ];then

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
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
EOF
      fi
    fi

    if [ $K8S_CP_COUNT = "3" ];then
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
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
- role: control-plane
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
- role: control-plane
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        runtime-config: api/all=true 
        storage-media-type: $REALLY_STORAGE_MEDIA_TYPE
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
- role: worker
  image: $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:$KIND_VERSION-$IMGTAG
EOF
    fi

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

    if [ $TEST_WHAT = "kind-e2e" ];then
    #TODO 将ginkgo跑在容器里面? 或者继续研究如何才能不丢失日志 (目前在github action 会丢失ginkgo的测试日志,但是使用官方的 e2e-k8s.sh 却不会丢失,奇怪)
    #--provider=skeleton       
    #--prefix=e2e --network=e2e \
      ginkgo --nodes=25                \
          --focus="."     \
          --skip="\[Serial\]|\[sig-storage\]|\[sig-storage, Slow\]|\[sig-storage\]\[Slow\]|\[Disruptive\]|\[Flaky\]|\[Feature:.+\]|PodSecurityPolicy|LoadBalancer|load.balancer|Simple.pod.should.support.exec.through.an.HTTP.proxy|subPath.should.support.existing|NFS|nfs|inline.execution.and.attach|should.be.rejected.when.no.endpoints.exist"   \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                               \
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

util::getbuild
util::deployk8s
util::runtests
