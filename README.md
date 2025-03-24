









# Extra: Add custom kube scheduler configuration file that favours ImageLocallity

### View current kube-scheduler configuration


View current options of kube-scheduler:
```
# ps auxf | grep kube-scheduler
root        1326  0.6  0.9 1292572 73884 ?       Ssl  09:43   0:54  \_ kube-scheduler --authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true
```

/etc/kubernetes/scheduler.conf only holds connection parameters to the cluster (e.g. it is a kubeconfig type of file)
Actual scheduler configuration is found in /etc/kubernetes/manifests/kube-scheduler.yaml:
```
# cat /etc/kubernetes/manifests/kube-scheduler.yaml 

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.k8s.io/kube-scheduler:v1.32.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-scheduler
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 10259
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```


### Add KubeSchedulerConfiguration via kubeadm-config.yaml

To install it must modify file on the filesystem, can not change scheduler config via kubectl.
see: https://kubernetes.io/docs/reference/scheduling/config/
```
You can customize the behavior of the kube-scheduler by writing a configuration file and passing its path as a command line argument.
```

Because cluster is created with kubeadm, add the options to kubeadm-config.yaml under ClusterConfiguration.scheduler.
kubeadm spec see: https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
and also: https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta4

```
# cat /root/kubeadm-config.yaml 

apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
localAPIEndpoint:
  advertiseAddress: 10.128.0.16
  name: master

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.31.0
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr apparently special value for flannel
  serviceSubnet: "10.255.0.0/16"

scheduler:
  extraArgs:
    - name: config
      value: "/etc/kubernetes/kube-scheduler-custom.conf"
  extraVolumes:
    - name: "kube-scheduler-custom-conf"
      hostPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      mountPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      readOnly: true
      pathType: File

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
```

Check that kubeadm config in-cluster matches the file on filesystem:

```
# kubectl get configmap -n kube-system kubeadm-config -o yaml
apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer: {}
    apiVersion: kubeadm.k8s.io/v1beta4
    caCertificateValidityPeriod: 87600h0m0s
    certificateValidityPeriod: 8760h0m0s
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controllerManager: {}
    dns: {}
    encryptionAlgorithm: RSA-2048
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: registry.k8s.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.32.1
    networking:
      dnsDomain: cluster.local
      podSubnet: 10.244.0.0/16
      serviceSubnet: 10.255.0.0/16
    proxy: {}
    scheduler: {}
kind: ConfigMap
metadata:
  creationTimestamp: "2025-01-26T07:24:04Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "26566"
  uid: 5da108b1-0d4e-4af8-bdb1-e18c98505685
```

Note that cluster version needs to be updated in the filesystem config v1.31.0 -> v1.32.1, appart from that everything matches.
Also note that localApiEndpoint lost .name property.


### Final config files

Final kubeadm-conf.yaml
```
# cat /root/kubeadm-config.yaml 

apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
localAPIEndpoint:
  advertiseAddress: 10.128.0.16

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.32.1
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr apparently special value for flannel
  serviceSubnet: "10.255.0.0/16"

scheduler:
  extraArgs:
    - name: config
      value: "/etc/kubernetes/kube-scheduler-custom.conf"
  extraVolumes:
    - name: "kube-scheduler-custom-conf"
      hostPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      mountPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      readOnly: true
      pathType: File

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
```


And final /etc/kubernetes/kube-scheduler-custom.conf, see: https://kubernetes.io/docs/reference/scheduling/config/

```
# cat /etc/kubernetes/kube-scheduler-custom.conf

apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: /etc/kubernetes/scheduler.conf
leaderElection:
  leaderElect: true
profiles:
  - schedulerName: default-scheduler
  - schedulerName: image-locality-scheduler
    plugins:
      score:
        enabled:
          - name: ImageLocality
            weight: 100
```


### Apply changed kubeadm config to reconfigure cluster

see: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/

Its possible to manually edit /etc/kubernetes/manifests which will re-create static the pod, but for IaC use kubeadm:

```
# kubeadm init phase control-plane scheduler --config /root/kubeadm-config.yaml
```

Note that I did NOT manually edit the kubeadm-config ConfigMap, only ran the init phase command.


At this point I forgot to create kube-scheduler-custom.conf, and got error on kube-scheduler-master pod:
```
 kubelet  MountVolume.SetUp failed for volume "kube-scheduler-custom-conf" : hostPath type check failed: /etc/kubernetes/kube-scheduler-custom.conf is not a file
```

After creating the file and manual restart of scheduler, all is working:
```
# kubectl delete pod -n kube-system kube-scheduler-master
```

Verify that scheduler uses new config file:
```
# ps axuf | grep scheduler
root       18578  0.7  0.8 1292572 68704 ?       Ssl  20:58   0:12  \_ kube-scheduler --authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --config=/etc/kubernetes/kube-scheduler-custom.conf --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true

# cat /etc/kubernetes/manifests/kube-scheduler.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --config=/etc/kubernetes/kube-scheduler-custom.conf
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.k8s.io/kube-scheduler:v1.32.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-scheduler
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 10259
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/kube-scheduler-custom.conf
      name: kube-scheduler-custom-conf
      readOnly: true
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/kube-scheduler-custom.conf
      type: File
    name: kube-scheduler-custom-conf
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```
