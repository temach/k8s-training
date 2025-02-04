# k8s-training

# Yandex Cloud
### Buy VMs
1 master and 3 workers, all Debian 11 (2 cpu, 8 ram, 30 gb ssd)

```
Host k8s-train-master
  User artem
  IdentityFile ~/.ssh/id_rsa
  HostName 89.169.150.208
```

Public IPs may change, so best use yc ssh
```
yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name master
yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1
```

List/Start/Stop instances:
```
# yc compute instances list
# yc compute instances start master & yc compute instances start worker1 & yc compute instances start worker2 & yc compute instances start worker3
# yc compute instances stop master & yc compute instances stop worker1 & yc compute instances stop worker2 & yc compute instances stop worker3
```


# Prepare vm

### Kubernetes getting started docs

see: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

Enable packet forwarding:
sysctl params required by setup, params persist across reboots
```
# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# sudo sysctl --system
```

### Install CRI (container)

I choose docker (but turns out under the hood docker uses containerd anyway):
```
# sudo apt update
# sudo apt upgrade
# sudo apt install docker.io
```

Install cri-docker for cri integration (see https://mirantis.github.io/cri-dockerd/usage/install/) on debian 11 bullseye:
```
# wget --show-progress 'https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.16/cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb' -o cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
# sudo dpkg -i cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
```

Also noticed that cri-docker binds to all addresses making it available over internet:
```
# sudo ss -lntp
State       Recv-Q   Send-Q     Local Address:Port         Peer Address:Port      Process                                    
LISTEN      0        4096           127.0.0.1:40437             0.0.0.0:*          users:(("containerd",pid=563,fd=12))      
LISTEN      0        128              0.0.0.0:22                0.0.0.0:*          users:(("sshd",pid=623,fd=3))             
LISTEN      0        128                 [::]:22                   [::]:*          users:(("sshd",pid=623,fd=4))             
LISTEN      0        4096                   *:35405                   *:*          users:(("cri-dockerd",pid=1636,fd=3))

```

Changed systemd file to bind to localhost only by adding "streaming-bind-addr" flag:
```
# vim /lib/systemd/system/cri-docker.service
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --streaming-bind-addr 127.0.0.1
# sudo systemctl enable cri-docker
```


### Install CNI (network) plugins

See instruction in flannel readme (https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually):
```
Flannel uses portmap as CNI network plugin by default;
when deploying Flannel ensure that the CNI Network plugins are installed in /opt/cni/bin
```

Install plugins:
```
# mkdir -p /opt/cni/bin
# wget --show-progress 'https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz' -o cni-plugins-linux-amd64-v1.6.2.tgz
# tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.6.2.tgz
```

### Install kubeadm, kubelet, kubectl

Kubelet must match the target kubernetes version.

Prepare debian to add custom ppa repos:
```
# apt install gpg
# sudo apt-get install ca-certificates
# sudo install -m 0755 -d /etc/apt/keyrings
```

Instruction from CRI-O repo (https://github.com/cri-o/packaging/blob/main/README.md#bootstrap-a-cluster-1)
And offical kubernetes v1.31 docs (https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)
Add kubernetes repository with specific version:
```
# KUBERNETES_VERSION=v1.31
# curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
```

Install components:
```
# apt update
# apt install -y kubelet kubeadm kubectl
# apt-mark hold kubelet kubeadm kubectl
```


### Optional final VM configs

These params are ok by default normally. Instructions from CRI-O readme, configure final vm params:
```
# swapoff -a
# modprobe br_netfilter
```

"br_netfilter" was actually already loaded by "bridge" kernel module. 


Useful links:
- https://github.com/cri-o/packaging/blob/main/README.md#distributions-using-deb-packages
- https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md
- https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/migrate-dockershim-dockerd/


### kubeadm init

Create config file /root/kubeadm-config.yaml.
Very useful docs: https://pkg.go.dev/k8s.io/kubernetes@v1.32.1/cmd/kubeadm/app/apis/kubeadm/v1beta4
Pass --pod-network-cird as flannel requests (https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md)
```
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
  name: master
localAPIEndpoint:
  advertiseAddress: 10.128.0.16

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.31.0
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr apparently special value for flannel
  serviceSubnet: "10.255.0.0/16"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration

```

Finally master init as root user:
```
# kubeadm init --config kubeadm-config.yaml

[init] Using Kubernetes version: v1.31.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0126 07:22:52.400720    4737 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.9" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local master] and IPs [10.255.0.1 10.128.0.16]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost master] and IPs [10.128.0.16 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost master] and IPs [10.128.0.16 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.729185ms
[api-check] Waiting for a healthy API server. This can take up to 4m0s
[api-check] The API server is healthy after 30.501394401s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node master as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node master as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: 0dklg3.04i3848i5b1wttin
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.128.0.16:6443 --token 0XXXXX.0XXXXXXXXXXXXXXn \
	--discovery-token-ca-cert-hash sha256:57XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXa
```

### Verify kubectl

```
root@master:~# export KUBECONFIG=/etc/kubernetes/admin.conf
root@master:~# kubectl get ns
NAME              STATUS   AGE
default           Active   3m28s
kube-node-lease   Active   3m27s
kube-public       Active   3m28s
kube-system       Active   3m28s
root@master:~# kubectl get nodes -o wide
NAME     STATUS     ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
master   NotReady   control-plane   8m21s   v1.31.5   10.128.0.16   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-33-amd64   docker://20.10.5+dfsg1
```

### Install Flannel

Install helm
```
# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Follow official flannel readme (https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-with-helm):
```
# kubectl create ns kube-flannel
# kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
# helm repo add flannel https://flannel-io.github.io/flannel/
```

Finally install:
```
# helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel
NAME: flannel
LAST DEPLOYED: Sun Jan 26 14:00:32 2025
NAMESPACE: kube-flannel
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Verify that coreDns has started:
```
# kubectl get pods -A
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE
kube-flannel   kube-flannel-ds-vklr7            1/1     Running   0               103s
kube-system    coredns-7c65d6cfc9-fztn5         1/1     Running   0               6h38m
kube-system    coredns-7c65d6cfc9-sjxrn         1/1     Running   0               6h38m
kube-system    etcd-master                      1/1     Running   1 (6m33s ago)   6h38m
kube-system    kube-apiserver-master            1/1     Running   1 (6m33s ago)   6h38m
kube-system    kube-controller-manager-master   1/1     Running   1 (6m33s ago)   6h38m
kube-system    kube-proxy-sg2zv                 1/1     Running   1 (6m33s ago)   6h38m
kube-system    kube-scheduler-master            1/1     Running   1 (6m33s ago)   6h38m
```
