#!/bin/bash
set -o errexit;
set -o pipefail;
set -o nounset;

function util::getbuild(){
  STEP_WHAT=${STEP_WHAT:-"none"}
  KIND_VERSION=${KIND_VERSION:-"v0.23.0"}
  if [ $STEP_WHAT = "getbuild" ];then 
    wget -q https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64
    chmod +x kind-linux-amd64 &&  mv kind-linux-amd64 /usr/local/bin/kind
  fi
}

# kind create cluster --image $KIND_IMG_REGISTRY/$KIND_IMG_USER/${KIND_IMG_REPO}:v0.22.0-v1.31.0-alpha.0-368-g47ad87e95fe
function util::deployk8s(){
  #TODO 支持使用vagrant部署虚拟机,在虚拟机里面跑测试?
  STEP_WHAT=${STEP_WHAT:-"none"}

   # deployk8s, runtests
  if [ $STEP_WHAT = "deployk8s" ];then 
    sudo ifconfig eth0:9 192.168.66.2 netmask 255.255.255.0 up
    sudo ifconfig eth0:9 up

    # deploy jaeger 
    # oras pull ghcr.io/liangyuanpeng/files:docker-compose-jaeger
    # curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-$(uname -m)
    # chmod +x /usr/local/bin/docker-compose
    # docker-compose -f docker-compose-jaeger-only.yml up -d 

    export KIND_VERSION=${KIND_VERSION:-"v0.23.0"}
    export IMGTAG=${IMGTAG:-"v1.30.0"}
    export STORAGE_MEDIA_TYPE=${STORAGE_MEDIA_TYPE:-"json"}
    export KIND_IMG_REPO=${KIND_IMG_REPO:-"kindest/testnode"}
    export KIND_IMG_REGISTRY=${KIND_IMG_REGISTRY:-"ghcr.io"}
    export KIND_IMG_USER=${KIND_IMG_USER:-"liangyuanpeng"}
    # k8s master 节点数量,  1master2node  3master2node
    export K8S_CP_COUNT=${K8S_CP_COUNT:-"1"}
    export WHICH_ETCD=${WHICH_ETCD:-"build-in"}
    #TODO k8s集群功能分类, 1.默认 2.all alpha=true 3. all beta=true 4. all alpha+beta=true
    export ENABLED_WHAT=${ENABLED_WHAT:-"default"}
    #TODO 1. 开启了apiserver-network-proxy的 k8s集群
    export ADDON_WHAT=${ADDON_WHAT:-"none"}

    export ETCD_VERSION=${ETCD_VERSION:-"v3.5.14"}
    wget -q https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    tar -xf etcd-${ETCD_VERSION}-linux-amd64.tar.gz && rm -f etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    mv etcd-${ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin/ && rm -rf etcd-${ETCD_VERSION}-linux-amd64

    mkdir -p _artifacts/testreport/
    if [ $WHICH_ETCD = "xline" ];then 
      echo "docker run xline"
      docker run -it -d -v $PWD/_artifacts/testreport/xline:/tmp/xline --name xline -p 2379:2379 -p 9100:9100 -p 9090:9090 ghcr.io/xline-kv/xline:latest xline --name node1 --members node1=0.0.0.0:2379 --data-dir /tmp/xline --storage-engine rocksdb --client-listen-urls=http://0.0.0.0:2379 --peer-listen-urls=http://0.0.0.0:2380,http://0.0.0.0:2381 --client-advertise-urls=http://0.0.0.0:2379 --peer-advertise-urls=http://0.0.0.0:2380,http://0.0.0.0:2381 
      docker ps
      # etcdctl put /hello world
      # etcdctl get /hello
    fi

    if [ $WHICH_ETCD = "etcd-main" ];then 
      sudo mkdir -p $PWD/_artifacts/testreport/etcd
      sudo chmod -R 777 $PWD/_artifacts/testreport/etcd
      docker run -it -d -v $PWD/_artifacts/testreport/etcd:/var/lib/etcd  --restart=always --name etcdmain -p 2379:2379 ghcr.io/liangyuanpeng/etcd:main-0-linux-amd64 etcd --data-dir /var/lib/etcd --experimental-watch-progress-notify-interval 1m --listen-client-urls http://0.0.0.0:2379 --advertise-client-urls http://0.0.0.0:2379
      docker logs etcdmain
    fi

    if [ $WHICH_ETCD = "xline-cluster" ];then 
      echo "xline cluster"
    fi

    if [ $WHICH_ETCD = "etcd-main-cluster5" ];then 
      echo "etcd cluster"
      docker-compose -f config/docker-compose-etcd.yml up -d
      docker-compose -f config/docker-compose-etcd.yml ps
    fi

    export REALLY_STORAGE_MEDIA_TYPE=${REALLY_STORAGE_MEDIA_TYPE:-"application/json"}
    #TODO 开启以下配置 测试矩阵
    IPFAMILY=${IPFAMILY:-"ipv4"} #ipv4 ipv6  双栈
    PROXY_MODE=${PROXY_MODE:-"iptables"} # iptables, ipvs, nftables

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
        envsubst  <  artifacts/kind_ci_template_in.yaml > kind-ci.yaml
      fi

      if [ $WHICH_ETCD = "etcd-main" ];then
        ETCD_ENDPOINTS=http://192.168.66.2:2379 envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      fi

      if [ $WHICH_ETCD = "xline" ];then
        ETCD_ENDPOINTS=http://192.168.66.2:2379 envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      fi

      if [ $WHICH_ETCD = "etcd-main-cluster5" ];then
        ETCD_ENDPOINTS="http://192.168.66.2:21379,http://192.168.66.2:22379,http://192.168.66.2:23379,http://192.168.66.2:24379,http://192.168.66.2:25379" envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      fi

    fi

    if [ $K8S_CP_COUNT = "3" ];then

      if [ $WHICH_ETCD = "xline" ];then 
        ETCD_ENDPOINTS=http://192.168.66.2:2379 envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      elif [ $WHICH_ETCD = "etcd-main" ];then
        ETCD_ENDPOINTS=http://192.168.66.2:2379 envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      elif [ $WHICH_ETCD = "etcd-main-cluster5" ];then
        ETCD_ENDPOINTS="http://192.168.66.2:21379,http://192.168.66.2:22379,http://192.168.66.2:23379,http://192.168.66.2:24379,http://192.168.66.2:25379" envsubst  <  artifacts/kind_ci_template.yaml > kind-ci.yaml
      else
        envsubst  <  artifacts/kind_ci_template_node5.yaml > kind-ci.yaml
      fi
    fi

    cat kind-ci.yaml
    mkdir -p _artifacts/testreport

    /usr/local/bin/kind create cluster \
    --name kind           \
    -v7 --wait 4m --retain --config=kind-ci.yaml
    
    cp ~/.kube/config _artifacts/

    pwd
    ls
    ls artifacts
    nohup kubectl taint nodes --all  node-role.kubernetes.io/control-plane- &
    #kubectl apply -f artifacts/k8s/ds.yaml
    kubectl apply -f artifacts/k8s/
    kubectl get node
    kubectl get ds -A
    kubectl get pod -A

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
  # make WHAT="test/e2e/e2e.test"
  #TODO 部署一些东西,作为干扰项,例如k8s内部署 etcd 集群. (只是部署,不做其他动作)
  # 以及部署一个 Daemonset, Deployment
  STEP_WHAT=${STEP_WHAT:-"none"}
  TESTS_WITH=${TESTS_WITH:-"ginkgo"}
  # ginkgo hydrophone
  TEST_WHAT=${TEST_WHAT:-"none"}
  if [ $STEP_WHAT = "runtests" ];then

    if [ $TEST_WHAT = "conformance-nodes1" ];then
      ginkgo -v --race --trace --nodes=1                \
          --focus="\[Conformance\]"     \
          --skip="Feature|Federation|machinery|PerformanceDNS|DualStack|Disruptive|Serial|Slow|KubeProxy|LoadBalancer|GCE|Netpol|NetworkPolicy|NodeConformance"   \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance" ];then
      ginkgo -v --race --trace --nodes=25                \
          --focus="\[Conformance\]"     \
          --skip="Feature|Federation|machinery|PerformanceDNS|DualStack|Disruptive|Serial|Slow|KubeProxy|LoadBalancer|GCE|Netpol|NetworkPolicy|NodeConformance"   \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-50" ];then
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="\[Conformance\]"     \
          --skip="Feature|Federation|machinery|PerformanceDNS|DualStack|Disruptive|Serial|Slow|KubeProxy|LoadBalancer|GCE|Netpol|NetworkPolicy|NodeConformance"   \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "ValidatingAdmissionPolicy" ];then
      ginkgo -v --race --trace --nodes=25                \
          --focus="ValidatingAdmissionPolicy"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "MutatingAdmissionPolicy" ];then
      ginkgo -v --race --trace --nodes=25                \
          --focus="MutatingAdmissionPolicy"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-lease" ];then
      echo "hello lease API should be available"
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="lease API should be available"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-sig-app" ];then
      echo "[sig-app, Conformance]"
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="\[sig-app, Conformance\]"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-sig-node" ];then
      echo "hello [sig-node, Conformance]"
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="\[sig-node, Conformance\]"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-sig-storage" ];then
      echo "hello [sig-storage, Conformance]"
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="\[sig-storage, Conformance\]"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    if [ $TEST_WHAT = "conformance-aggregator" ];then
      echo "hello Should be able to support the 1.17 Sample API Server using the current Aggregator"
      ginkgo --repeat=50 -v --race --trace --nodes=25                \
          --focus="Should be able to support the 1.17 Sample API Server using the current Aggregator"     \
          /usr/local/bin/e2e.test                       \
          --                                            \
          --kubeconfig=${PWD}/_artifacts/config     \
          --provider=local                              \
          --dump-logs-on-failure=true                  \
          --report-dir=${PWD}/_artifacts/testreport            \
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi
    
    #TODO test feature watchList
    

    

    # if [ $TEST_WHAT = "kind-e2e" ];then
    # #--provider=skeleton       
    # #--prefix=e2e --network=e2e \
    #   ginkgo -v --race --trace --nodes=25                \
    #       --focus="."     \
    #       --skip="\[Serial\]|\[sig-storage\]|\[sig-storage, Slow\]|\[sig-storage\]\[Slow\]|\[Disruptive\]|\[Flaky\]|\[Feature:.+\]|PodSecurityPolicy|LoadBalancer|load.balancer|Simple.pod.should.support.exec.through.an.HTTP.proxy|subPath.should.support.existing|NFS|nfs|inline.execution.and.attach|should.be.rejected.when.no.endpoints.exist"   \
    #       /usr/local/bin/e2e.test                       \
    #       --                                            \
    #       --kubeconfig=${PWD}/_artifacts/config     \
    #       --provider=local                               \
    #       --dump-logs-on-failure=true                  \
    #       --report-dir=${PWD}/_artifacts/testreport            \
    #       --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    # fi

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
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
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
          --disable-log-dump=true | tee ${PWD}/_artifacts/testreport/ginkgo-e2e.log
    fi

    # if [ $TEST_WHAT = "kind-e2e" ];then
    #   export FOCUS=.
      
    #   curl -sSL https://kind.sigs.k8s.io/dl/latest/linux-amd64.tgz | tar xvfz - -C "${PATH%%:*}/" && e2e-k8s.sh
    # fi

    touch ${PWD}/_artifacts/testreport/ginkgo-e2e.log

  fi
}

#TODO run wirh azure pipeline
util::getbuild
util::deployk8s
util::runtests
