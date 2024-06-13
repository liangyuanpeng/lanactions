_nodes=[{
        role = "control-plane",
        image = option("kindimage",default="kindest/node:v1.30.0")
        extraMounts = [
            {
                hostPath = "/home/runner/work/lanactions/lanactions/config/apiserver-audit-policy.yaml",
                containerPath = "/etc/kubernetes/audit-policy/apiserver-audit-policy.yaml"
            }
        ]
        kubeadmConfigPatches = [
"""\
kind: ClusterConfiguration
etcd:
  external:
    endpoints: [${ETCD_ENDPOINTS}]
apiServer:
  extraArgs:
    runtime-config: api/all=true
    storage-media-type: ${REALLY_STORAGE_MEDIA_TYPE}
    audit-log-path: /var/log/audit/kube-apiserver-audit.log
    audit-policy-file: /etc/kubernetes/audit-policy/apiserver-audit-policy.yaml
  extraVolumes:
    - name: "audit-logs"
      hostPath: /var/log/audit
      mountPath: /var/log/audit
    - name: audit-policy
      hostPath: /etc/kubernetes/audit-policy
      mountPath: /etc/kubernetes/audit-policy
"""
        ]
}

]


_count = option("count",default="default")
if _count == 3:
    print("The value of a is", _count)
    _nodes+=[{
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    }
    ]
elif _count == 5:
    _nodes+=[
        {
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    },{
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    },{
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    },{
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    },{
        role = "worker"
        image = option("kindimage",default="kindest/node:v1.30.0")
    }
    ]

#print("The value of a is", _count)
#print(_count==3)
#print(_count==5)


kind = "Cluster"
apiVersion = "kind.x-k8s.io/v1alpha4"
networking = {
     #https://kcl-lang.io/docs/user_docs/support/faq-kcl#39-how-to-set-default-value-for-option-function-in-kcl
    apiServerAddress = option("apiaddress",default="0.0.0.0")
    ipFamily = option("ipFamily",default="ipv4")
    kubeProxyMode = option("kubeProxyMode",default="iptables")
}
nodes=_nodes