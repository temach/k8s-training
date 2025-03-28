# k8s-training

Выжимка команд без вывода/комментариев собрана в файлах:
- master.sh
- worker.sh
- update-master.sh
- update-worker.sh



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


# Setup Master vm

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
# wget --show-progress 'https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.16/cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb' -O cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
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
# wget --show-progress 'https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz' -O cni-plugins-linux-amd64-v1.6.2.tgz
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
However! If docker iptables is disabled (e.g. when running k8s on pure nftables), then bridge is not loaded and br_netfilter is not loaded and flannel will fail.


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


# Setup worker vm

### Similar commands to master setup
```
# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
# sudo sysctl --system

# sudo apt update
# sudo apt upgrade
# sudo apt install docker.io

# wget --show-progress 'https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.16/cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb' -O cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
# sudo dpkg -i cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
```

Manually change ExecStart line to bind to local interface only:
```
# vim /lib/systemd/system/cri-docker.service
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --streaming-bind-addr 127.0.0.1

# sudo systemctl enable cri-docker
```

Continue:
```
# mkdir -p /opt/cni/bin
# wget --show-progress 'https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz' -O cni-plugins-linux-amd64-v1.6.2.tgz
# tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.6.2.tgz

# apt install gpg
# sudo apt-get install ca-certificates
# sudo install -m 0755 -d /etc/apt/keyrings

# export KUBERNETES_VERSION=v1.31
# curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# apt update
# apt install -y kubelet kubeadm kubectl
# apt-mark hold kubelet kubeadm kubectl
```

### worker1 kubeadm-config.yaml

```
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
nodeRegistration:
  name: worker1
  criSocket: unix:///var/run/cri-dockerd.sock
discovery:
  bootstrapToken:
    apiServerEndpoint: "10.128.0.16:6443"
    token: "0XXXXX.0XXXXXXXXXXXXXXn"
    caCertHashes: 
      - "sha256:57XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXa"
    unsafeSkipCAVerification: false

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
```

Finally kubeadm join:
```
# kubeadm join --config kubeadm-config.yaml 
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.767425ms
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

And repeat for other workers, changing their nodeRegistration.name parameter.


# Verify cluster nodes

```
# kubectl get nodes -o wide

NAME      STATUS     ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
master    Ready      control-plane   14h   v1.31.5   10.128.0.16   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-33-amd64   docker://20.10.5+dfsg1
worker1   Ready      <none>          52m   v1.31.5   10.128.0.25   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-33-amd64   docker://20.10.5+dfsg1
worker2   NotReady   <none>          11s   v1.31.5   10.128.0.26   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   docker://20.10.5+dfsg1
worker3   NotReady   <none>          19s   v1.31.5   10.128.0.3    <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   docker://20.10.5+dfsg1
```


# Upgrade master

See: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

(Alternatively upgrade via kubeadm-config.yaml file, see: https://blog.honosoft.com/2020/01/31/kubeadm-how-to-upgrade-update-your-configuration/)

Bump repo version to 1.32
```
# vim /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
```

Get new versions:
```
# apt update
# apt list --upgradable
Listing... Done
cri-tools/unknown 1.32.0-1.1 amd64 [upgradable from: 1.31.1-1.1]
kubeadm/unknown 1.32.1-1.1 amd64 [upgradable from: 1.31.5-1.1]
kubectl/unknown 1.32.1-1.1 amd64 [upgradable from: 1.31.5-1.1]
kubelet/unknown 1.32.1-1.1 amd64 [upgradable from: 1.31.5-1.1]
kubernetes-cni/unknown 1.6.0-1.1 amd64 [upgradable from: 1.5.1-1.1]
```

Package cri-docker does not need update.

At this point I realised that manually installing cni plugins was a waste of time, because they are pulled as dependency of kubelet and my hand intsall into /opt/cni/bin was overriden by apt with version 1.5.1 binaries.
```
# apt-cache rdepends --installed kubernetes-cni
kubernetes-cni
Reverse Depends:
  kubelet
```

Upgrade kubeadm:
```
# apt-mark unhold kubeadm
# apt install -y kubeadm
# apt-mark hold kubeadm
```


Check possible upgrade plan:
```
# kubeadm upgrade plan
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade/config] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.31.0
[upgrade/versions] kubeadm version: v1.32.1
[upgrade/versions] Target version: v1.32.1
[upgrade/versions] Latest version in the v1.31 series: v1.31.5

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE      CURRENT   TARGET

Upgrade to the latest version in the v1.31 series:

COMPONENT                 NODE      CURRENT    TARGET
kube-apiserver            master    v1.31.0    v1.31.5
kube-controller-manager   master    v1.31.0    v1.31.5
kube-scheduler            master    v1.31.0    v1.31.5
kube-proxy                          1.31.0     v1.31.5
CoreDNS                             v1.11.3    v1.11.3
etcd                      master    3.5.15-0   3.5.16-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.31.5

_____________________________________________________________________

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE      CURRENT   TARGET
kubelet     master    v1.31.5   v1.32.1
kubelet     worker1   v1.31.5   v1.32.1
kubelet     worker2   v1.31.5   v1.32.1
kubelet     worker3   v1.31.5   v1.32.1

Upgrade to the latest stable version:

COMPONENT                 NODE      CURRENT    TARGET
kube-apiserver            master    v1.31.0    v1.32.1
kube-controller-manager   master    v1.31.0    v1.32.1
kube-scheduler            master    v1.31.0    v1.32.1
kube-proxy                          1.31.0     v1.32.1
CoreDNS                             v1.11.3    v1.11.3
etcd                      master    3.5.15-0   3.5.16-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.32.1

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________

```


Skipping latest patch version 1.31.5 because trying to upgrade to it fails now:
```
# kubeadm upgrade apply v1.31.5 
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[upgrade/preflight] Running preflight checks
[upgrade] Running cluster health checks
[upgrade/preflight] You have chosen to upgrade the cluster version to "v1.31.5"
[upgrade/versions] Cluster version: v1.31.0
[upgrade/versions] kubeadm version: v1.32.1
error execution phase preflight: the version argument is invalid due to these errors:

	- Kubeadm version v1.32.1 can only be used to upgrade to Kubernetes version 1.32

Can be bypassed if you pass the --force flag
To see the stack trace of this error execute with --v=5 or higher
```

Updating master to 1.32.1
```
# kubeadm upgrade apply v1.32.1

[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[upgrade/preflight] Running preflight checks
[upgrade] Running cluster health checks
[upgrade/preflight] You have chosen to upgrade the cluster version to "v1.32.1"
[upgrade/versions] Cluster version: v1.31.0
[upgrade/versions] kubeadm version: v1.32.1
[upgrade] Are you sure you want to proceed? [y/N]: y
[upgrade/preflight] Pulling images required for setting up a Kubernetes cluster
[upgrade/preflight] This might take a minute or two, depending on the speed of your internet connection
[upgrade/preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0126 23:44:46.495587   98016 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.9" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
[upgrade/control-plane] Upgrading your static Pod-hosted control plane to version "v1.32.1" (timeout: 5m0s)...
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests1417830454"
[upgrade/staticpods] Preparing for "etcd" upgrade
[upgrade/staticpods] Renewing etcd-server certificate
[upgrade/staticpods] Renewing etcd-peer certificate
[upgrade/staticpods] Renewing etcd-healthcheck-client certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/etcd.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-01-26-23-45-41/etcd.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
E0126 23:47:13.000879   98016 request.go:1332] Unexpected error when reading response body: net/http: request canceled (Client.Timeout or context cancellation while reading body)
[apiclient] Found 1 Pods for label selector component=etcd
[upgrade/staticpods] Component "etcd" upgraded successfully!
[upgrade/etcd] Waiting for etcd to become available
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-01-26-23-45-41/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-01-26-23-45-41/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-01-26-23-45-41/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade/control-plane] The control plane instance for this node was successfully upgraded!
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upgrad/kubeconfig] The kubeconfig files for this node were successfully upgraded!
W0126 23:50:14.425175   98016 postupgrade.go:117] Using temporary directory /etc/kubernetes/tmp/kubeadm-kubelet-config610526404 for kubelet config. To override it set the environment variable KUBEADM_UPGRADE_DRYRUN_DIR
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config610526404/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
[upgrade/bootstrap-token] Configuring bootstrap token and cluster-info RBAC rules
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade] SUCCESS! A control plane node of your cluster was upgraded to "v1.32.1".

[upgrade] Now please proceed with upgrading the rest of the nodes by following the right order.
```

Finish master upgrade:
```
# kubectl drain master --ignore-daemonsets
# apt-mark unhold kubelet kubectl && apt-get update && sudo apt-get install -y kubelet kubectl && apt-mark hold kubelet kubectl
# systemctl daemon-reload
# systemctl restart kubelet
# kubectl uncordon master
```

Verify upgrade:
```
kubectl get nodes
NAME      STATUS   ROLES           AGE    VERSION
master    Ready    control-plane   16h    v1.32.1
worker1   Ready    <none>          3h3m   v1.31.5
worker2   Ready    <none>          131m   v1.31.5
worker3   Ready    <none>          131m   v1.31.5
```


# Upgrade worker nodes


```
# vim /etc/apt/sources.list.d//kubernetes.list 
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

# apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm && apt-mark hold kubeadm
# kubeadm upgrade node

# kubectl drain worker1 --ignore-daemonsets

# apt-mark unhold kubelet kubectl && apt-get update && apt-get install -y kubelet kubectl && apt-mark hold kubelet kubectl
# systemctl daemon-reload
# systemctl restart kubelet

# kubectl uncordon worker1

```
Repeat for other worker nodes.


Verify:
```
kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
master    Ready    control-plane   16h     v1.32.1   10.128.0.16   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-33-amd64   docker://20.10.5+dfsg1
worker1   Ready    <none>          3h19m   v1.32.1   10.128.0.25   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-33-amd64   docker://20.10.5+dfsg1
worker2   Ready    <none>          147m    v1.32.1   10.128.0.26   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   docker://20.10.5+dfsg1
worker3   Ready    <none>          147m    v1.32.1   10.128.0.3    <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   docker://20.10.5+dfsg1
```



# Extra: kube-proxy enforce nftables mode (the best of 4 kube-proxy modes: userspace, iptables, ipvs/lvs, nftables)

See: https://kubernetes.io/blog/2025/02/28/nftables-kube-proxy/#future-plans
Also see: https://kubernetes.io/docs/reference/networking/virtual-ips/#proxy-modes
Also see: https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3866-nftables-proxy/README.md

### update debian VMs

Must have:
- kernel version ($ uname -a) >5.3
- $ nft --version > 1.0.0

Get a new debian 12 VM and verify that Debian 12 matches version requirements:
```
worker4:~# nft --version
nftables v1.0.6 (Lester Gooch #5)
worker4:~# uname -a
Linux worker4 6.1.0-31-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.128-1 (2025-02-07) x86_64 GNU/Linux
```

Because its a single configmap for all kube-proxy pods they better all run in the same mode:
(also see: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#customizing-kube-proxy)

So upgrade Debian 11 nodes, to Debian 12, on each node to allow nftables mode:
```
apt update
# resolve old/new config prompts
apt upgrade -y
apt full-upgrade -y
reboot
# replace "bullseye" with "bookworm" in apt sources
vim /etc/apt/sources.list 
apt update
# there will be many prompts and config resolutions
apt full-upgrade -y
# trigger grub config update by autoremoving old kernel, so we reboot into latest kernel
apt autoremove
reboot
```

### kube-proxy enforce mode nftables

Get current config:
```
root@master:~# k get cm -n kube-system kube-proxy -o yaml
apiVersion: v1
data:
  config.conf: |-
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    bindAddress: 0.0.0.0
    bindAddressHardFail: false
    clientConnection:
      acceptContentTypes: ""
      burst: 0
      contentType: ""
      kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
      qps: 0
    clusterCIDR: 10.244.0.0/16
    configSyncPeriod: 0s
    conntrack:
      maxPerCore: null
      min: null
      tcpBeLiberal: false
      tcpCloseWaitTimeout: null
      tcpEstablishedTimeout: null
      udpStreamTimeout: 0s
      udpTimeout: 0s
    detectLocal:
      bridgeInterface: ""
      interfaceNamePrefix: ""
    detectLocalMode: ""
    enableProfiling: false
    healthzBindAddress: ""
    hostnameOverride: ""
    iptables:
      localhostNodePorts: null
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    ipvs:
      excludeCIDRs: null
      minSyncPeriod: 0s
      scheduler: ""
      strictARP: false
      syncPeriod: 0s
      tcpFinTimeout: 0s
      tcpTimeout: 0s
      udpTimeout: 0s
    kind: KubeProxyConfiguration
    logging:
      flushFrequency: 0
      options:
        json:
          infoBufferSize: "0"
        text:
          infoBufferSize: "0"
      verbosity: 0
    metricsBindAddress: ""
    mode: ""
    nftables:
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    nodePortAddresses: null
    oomScoreAdj: null
    portRange: ""
    showHiddenMetricsForVersion: ""
    winkernel:
      enableDSR: false
      forwardHealthCheckVip: false
      networkName: ""
      rootHnsEndpointName: ""
      sourceVip: ""
  kubeconfig.conf: |-
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        server: https://10.128.0.16:6443
      name: default
    contexts:
    - context:
        cluster: default
        namespace: default
        user: default
      name: default
    current-context: default
    users:
    - name: default
      user:
        tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
kind: ConfigMap
metadata:
  creationTimestamp: "2025-01-26T07:24:05Z"
  labels:
    app: kube-proxy
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "260"
  uid: 0778a320-xxxx-xxxx-xxxx-a3be640872c3
```


Update /root/kubeadm-config.yaml to have `mode: nftables` on one of the nodes (e.g. on master):
```
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: nftables
```

Its possible to manually edit the configmap, but for IaC use kubeadm:

see: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/
```
# kubeadm init phase addon kube-proxy --config /root/kubeadm-config.yaml
[addons] Applied essential addon: kube-proxy
```

Note that I did NOT manually edit the kubeadm-config ConfigMap, only ran the init phase command.


Verify "mode: nftables" changes in configmap:
```
# k get cm -n kube-system kube-proxy -o yaml
apiVersion: v1
data:
  config.conf: |-
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    bindAddress: 0.0.0.0
    bindAddressHardFail: false
    clientConnection:
      acceptContentTypes: ""
      burst: 0
      contentType: ""
      kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
      qps: 0
    clusterCIDR: 10.244.0.0/16
    configSyncPeriod: 0s
    conntrack:
      maxPerCore: null
      min: null
      tcpBeLiberal: false
      tcpCloseWaitTimeout: null
      tcpEstablishedTimeout: null
      udpStreamTimeout: 0s
      udpTimeout: 0s
    detectLocal:
      bridgeInterface: ""
      interfaceNamePrefix: ""
    detectLocalMode: ""
    enableProfiling: false
    healthzBindAddress: ""
    hostnameOverride: ""
    iptables:
      localhostNodePorts: null
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    ipvs:
      excludeCIDRs: null
      minSyncPeriod: 0s
      scheduler: ""
      strictARP: false
      syncPeriod: 0s
      tcpFinTimeout: 0s
      tcpTimeout: 0s
      udpTimeout: 0s
    kind: KubeProxyConfiguration
    logging:
      flushFrequency: 0
      options:
        json:
          infoBufferSize: "0"
        text:
          infoBufferSize: "0"
      verbosity: 0
    metricsBindAddress: ""
    mode: nftables
    nftables:
      masqueradeAll: false
      masqueradeBit: null
      minSyncPeriod: 0s
      syncPeriod: 0s
    nodePortAddresses: null
    oomScoreAdj: null
    portRange: ""
    showHiddenMetricsForVersion: ""
    winkernel:
      enableDSR: false
      forwardHealthCheckVip: false
      networkName: ""
      rootHnsEndpointName: ""
      sourceVip: ""
  kubeconfig.conf: |-
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        server: https://10.128.0.16:6443
      name: default
    contexts:
    - context:
        cluster: default
        namespace: default
        user: default
      name: default
    current-context: default
    users:
    - name: default
      user:
        tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
kind: ConfigMap
metadata:
  creationTimestamp: "2025-01-26T07:24:05Z"
  labels:
    app: kube-proxy
  name: kube-proxy
  namespace: kube-system
  resourceVersion: "402442"
  uid: 0778a320-9e13-42c0-9dc0-a3be640872c3
```

Restart the kube-proxy pods and do a node reboot. Now verify that old iptable rules were cleared and kube-proxy create two new nft tables for itself:
```
# nft list tables
table ip nat
table ip filter
table ip mangle
table ip6 mangle
table ip6 nat
table ip6 filter
table ip kube-proxy
table ip6 kube-proxy
```

Example rules:
```
# nft -a list table kube-proxy
table ip kube-proxy { # handle 18
	comment "rules for kube-proxy"
	set cluster-ips { # handle 39
		type ipv4_addr
		comment "Active ClusterIPs"
		elements = { 10.255.0.1, 10.255.0.10,
			     10.255.8.50, 10.255.10.67,
			     10.255.36.158, 10.255.233.197 }
	}

	set nodeport-ips { # handle 41
		type ipv4_addr
		comment "IPs that accept NodePort traffic"
		elements = { 10.128.0.25 }
	}

	map no-endpoint-services { # handle 42
		type ipv4_addr . inet_proto . inet_service : verdict
		comment "vmap to drop or reject packets to services with no endpoints"
	}

	map no-endpoint-nodeports { # handle 43
		type inet_proto . inet_service : verdict
		comment "vmap to drop or reject packets to service nodeports with no endpoints"
	}

	map firewall-ips { # handle 48
		type ipv4_addr . inet_proto . inet_service : verdict
		comment "destinations that are subject to LoadBalancerSourceRanges"
	}

	map service-ips { # handle 50
		type ipv4_addr . inet_proto . inet_service : verdict
		comment "ClusterIP, ExternalIP and LoadBalancer IP traffic"
		elements = { 10.255.0.10 . tcp . 53 : goto service-NWBZK7IH-kube-system/kube-dns/tcp/dns-tcp,
			     10.255.0.10 . udp . 53 : goto service-FY5PMXPG-kube-system/kube-dns/udp/dns,
			     10.255.36.158 . tcp . 8000 : goto service-MJTK4JPM-home/http-server/tcp/mainhttp,
			     10.128.0.16 . tcp . 80 : goto external-TAO5FKKM-ingress-nginx/ingress-nginx-controller/tcp/http,
			     10.128.0.25 . tcp . 80 : goto external-VQPS6G77-home/http-server-external-ip/tcp/mainhttp,
			     10.255.8.50 . tcp . 80 : goto service-VQPS6G77-home/http-server-external-ip/tcp/mainhttp,
			     10.255.10.67 . tcp . 80 : goto service-TAO5FKKM-ingress-nginx/ingress-nginx-controller/tcp/http,
			     10.255.0.1 . tcp . 443 : goto service-2QRHZV4L-default/kubernetes/tcp/https,
			     10.128.0.16 . tcp . 443 : goto external-FRX3YWVZ-ingress-nginx/ingress-nginx-controller/tcp/https,
			     10.255.10.67 . tcp . 443 : goto service-FRX3YWVZ-ingress-nginx/ingress-nginx-controller/tcp/https,
			     10.255.233.197 . tcp . 443 : goto service-GZRGW4S7-ingress-nginx/ingress-nginx-controller-admission/tcp/https-webhook,
			     10.255.0.10 . tcp . 9153 : goto service-AS2KJYAD-kube-system/kube-dns/tcp/metrics }
	}

	map service-nodeports { # handle 51
		type inet_proto . inet_service : verdict
		comment "NodePort traffic"
	}

	chain endpoint-573J25N3-default/kubernetes/tcp/https__10.128.0.16/6443 { # handle 54
		ip saddr 10.128.0.16 jump mark-for-masquerade # handle 59
		meta l4proto tcp dnat to 10.128.0.16:6443 # handle 60
	}

	chain service-2QRHZV4L-default/kubernetes/tcp/https { # handle 55
		ip daddr 10.255.0.1 tcp dport 443 ip saddr != 10.244.0.0/16 jump mark-for-masquerade # handle 56
		numgen random mod 1 vmap { 0 : goto endpoint-573J25N3-default/kubernetes/tcp/https__10.128.0.16/6443 } # handle 58
	}

	chain endpoint-ZRZOUO6E-home/http-server/tcp/mainhttp__10.244.1.71/8000 { # handle 61
		ip saddr 10.244.1.71 jump mark-for-masquerade # handle 139
		meta l4proto tcp dnat to 10.244.1.71:8000 # handle 140
	}

	chain service-MJTK4JPM-home/http-server/tcp/mainhttp { # handle 62
		ip daddr 10.255.36.158 tcp dport 8000 ip saddr != 10.244.0.0/16 jump mark-for-masquerade # handle 136
		numgen random mod 4 vmap { 0 : goto endpoint-ZRZOUO6E-home/http-server/tcp/mainhttp__10.244.1.71/8000, 1 : goto endpoint-6JPGGG4H-home/http-server/tcp/mainhttp__10.244.1.72/8000, 2 : goto endpoint-HH426HHC-home/http-server/tcp/mainhttp__10.244.1.73/8000, 3 : goto endpoint-I3S2YGGE-home/http-server/tcp/mainhttp__10.244.1.76/8000 } # handle 138
	}
    
	chain endpoint-6JPGGG4H-home/http-server/tcp/mainhttp__10.244.1.72/8000 { # handle 78
		ip saddr 10.244.1.72 jump mark-for-masquerade # handle 141
		meta l4proto tcp dnat to 10.244.1.72:8000 # handle 142
	}

	chain endpoint-I3S2YGGE-home/http-server/tcp/mainhttp__10.244.1.76/8000 { # handle 96
		ip saddr 10.244.1.76 jump mark-for-masquerade # handle 145
		meta l4proto tcp dnat to 10.244.1.76:8000 # handle 146
    }

   	chain endpoint-HH426HHC-home/http-server/tcp/mainhttp__10.244.1.73/8000 { # handle 135
		ip saddr 10.244.1.73 jump mark-for-masquerade # handle 143
		meta l4proto tcp dnat to 10.244.1.73:8000 # handle 144
	}


....

```


### flannel set enableNFTables true

see: https://github.com/flannel-io/flannel/blob/master/Documentation/configuration.md#nftables-mode

```
# helm upgrade flannel --set podCidr="10.244.0.0/16" --set flannel.enableNFTables=true --namespace kube-flannel flannel/flannel
```

Verify that flannel created tables for itself after kube-flannel pod recreated:
```
# nft list tables
table ip nat
table ip filter
table ip mangle
table ip6 mangle
table ip6 nat
table ip6 filter
table ip kube-proxy
table ip6 kube-proxy
table ip flannel-ipv4
table ip6 flannel-ipv6
```

Example rules:
```
# nft list table flannel-ipv4
table ip flannel-ipv4 {
	comment "rules for flannel-ipv4"
	chain postrtg {
		comment "chain to manage traffic masquerading by flannel"
		type nat hook postrouting priority srcnat; policy accept;
		meta mark 0x00004000 return
		ip saddr 10.244.1.0/24 ip daddr 10.244.0.0/16 return
		ip saddr 10.244.0.0/16 ip daddr 10.244.1.0/24 return
		ip saddr != 10.244.1.0/24 ip daddr 10.244.0.0/16 return
		ip saddr 10.244.0.0/16 ip daddr != 224.0.0.0/4 masquerade fully-random
		ip saddr != 10.244.0.0/16 ip daddr 10.244.0.0/16 masquerade fully-random
	}

	chain forward {
		comment "chain to accept flannel traffic"
		type filter hook forward priority filter; policy accept;
		ip saddr 10.244.0.0/16 accept
		ip daddr 10.244.0.0/16 accept
	}
}
```



### docker caveat

see: https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file

If using docker, better disable its handing of iptables all together :
```
# cat /etc/docker/daemon.json
{
  "iptables": false,
  "ip6tables": false
}
# reboot
```

But after reboot flannel failes:
```
root@master:~# k get pods -A -o wide
NAMESPACE       NAME                                       READY   STATUS             RESTARTS         AGE     IP            NODE      NOMINATED NODE   READINESS GATES
home            http-server-56bb7f7b5b-6hnnf               0/1     Error              5                3d3h    <none>        worker1   <none>           <none>
home            http-server-56bb7f7b5b-b4rm5               0/1     Error              5                3d3h    <none>        worker1   <none>           <none>
home            http-server-56bb7f7b5b-f2btm               0/1     Error              5                3d3h    <none>        worker1   <none>           <none>
home            http-server-56bb7f7b5b-rbvk2               0/1     Error              8                16d     <none>        worker1   <none>           <none>
ingress-nginx   ingress-nginx-controller-cd9d6bbd7-df6w5   0/1     Error              10               15d     <none>        worker1   <none>           <none>
kube-flannel    kube-flannel-ds-hrzrx                      0/1     CrashLoopBackOff   10 (3m55s ago)   52m     10.128.0.25   worker1   <none>           <none>
kube-flannel    kube-flannel-ds-kt2mh                      0/1     CrashLoopBackOff   11 (4m28s ago)   53m     10.128.0.3    worker3   <none>           <none>
kube-flannel    kube-flannel-ds-q2gl4                      0/1     CrashLoopBackOff   10 (4m51s ago)   53m     10.128.0.26   worker2   <none>           <none>
kube-flannel    kube-flannel-ds-qvj4z                      0/1     CrashLoopBackOff   6 (3m7s ago)     9m5s    10.128.0.16   master    <none>           <none>
kube-system     coredns-7c65d6cfc9-8t6pl                   0/1     Completed          7                3d15h   <none>        worker1   <none>           <none>
kube-system     coredns-7c65d6cfc9-pk4xt                   0/1     Completed          11               18d     <none>        master    <none>           <none>
kube-system     etcd-master                                1/1     Running            18 (32m ago)     48d     10.128.0.16   master    <none>           <none>
kube-system     kube-apiserver-master                      1/1     Running            18 (32m ago)     48d     10.128.0.16   master    <none>           <none>
kube-system     kube-controller-manager-master             1/1     Running            19 (32m ago)     48d     10.128.0.16   master    <none>           <none>
kube-system     kube-proxy-bp57z                           1/1     Running            4 (33m ago)      2d19h   10.128.0.25   worker1   <none>           <none>
kube-system     kube-proxy-hkklk                           1/1     Running            4 (32m ago)      2d19h   10.128.0.16   master    <none>           <none>
kube-system     kube-proxy-x4qcl                           1/1     Running            1 (33m ago)      53m     10.128.0.26   worker2   <none>           <none>
kube-system     kube-proxy-z5ztj                           1/1     Running            1 (33m ago)      53m     10.128.0.3    worker3   <none>           <none>
kube-system     kube-scheduler-master                      1/1     Running            14 (32m ago)     18d     10.128.0.16   master    <none>           <none>
```

Looking at logs:
```
root@master:~# k logs -n kube-flannel kube-flannel-ds-qvj4z
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-plugin (init), install-cni (init)
I0316 18:45:17.771355       1 main.go:211] CLI flags config: {etcdEndpoints:http://127.0.0.1:4001,http://127.0.0.1:2379 etcdPrefix:/coreos.com/network etcdKeyfile: etcdCertfile: etcdCAFile: etcdUsername: etcdPassword: version:false kubeSubnetMgr:true kubeApiUrl: kubeAnnotationPrefix:flannel.alpha.coreos.com kubeConfigFile: iface:[] ifaceRegex:[] ipMasq:true ifaceCanReach: subnetFile:/run/flannel/subnet.env publicIP: publicIPv6: subnetLeaseRenewMargin:60 healthzIP:0.0.0.0 healthzPort:0 iptablesResyncSeconds:5 iptablesForwardRules:true netConfPath:/etc/kube-flannel/net-conf.json setNodeNetworkUnavailable:true}
W0316 18:45:17.771489       1 client_config.go:618] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0316 18:45:17.785822       1 kube.go:139] Waiting 10m0s for node controller to sync
I0316 18:45:17.785886       1 kube.go:469] Starting kube subnet manager
I0316 18:45:17.791551       1 kube.go:490] Creating the node lease for IPv4. This is the n.Spec.PodCIDRs: [10.244.0.0/24]
I0316 18:45:17.791598       1 kube.go:490] Creating the node lease for IPv4. This is the n.Spec.PodCIDRs: [10.244.1.0/24]
I0316 18:45:17.791608       1 kube.go:490] Creating the node lease for IPv4. This is the n.Spec.PodCIDRs: [10.244.2.0/24]
I0316 18:45:17.791615       1 kube.go:490] Creating the node lease for IPv4. This is the n.Spec.PodCIDRs: [10.244.3.0/24]
I0316 18:45:18.786787       1 kube.go:146] Node controller sync successful
I0316 18:45:18.786823       1 main.go:231] Created subnet manager: Kubernetes Subnet Manager - master
I0316 18:45:18.786829       1 main.go:234] Installing signal handlers
I0316 18:45:18.787180       1 main.go:468] Found network config - Backend type: vxlan
E0316 18:45:18.787279       1 main.go:268] Failed to check br_netfilter: stat /proc/sys/net/bridge/bridge-nf-call-iptables: no such file or directory
```

Remedy flannel with loading netfilter kernel module:
```
# modprobe br_netfilter
```

Then manually delete and recreate all flannel pods and everything will work.



# Setup kubectl from local machine to remote yc cloud

Add static ip to yc cloud master machine in yc WEB GUI, because its a pain if ip floats.

Current setup:
```
$ yc compute instances list
+---------+---------+-----------------+-------------+
|  NAME   | STATUS  |   EXTERNAL IP   | INTERNAL IP |
+---------+---------+-----------------+-------------+
| master  | RUNNING | 158.160.61.136  | 10.128.0.16 |
| worker1 | RUNNING | 158.160.36.172  | 10.128.0.25 |
| worker2 | RUNNING | 89.169.144.19   | 10.128.0.26 |
| worker3 | RUNNING | 158.160.111.216 | 10.128.0.3  |
+---------+---------+-----------------+-------------+
```

Check that api server is reachable:
```
$ nmap 158.160.61.136 -p 6443
```

Anyhow copy remote /etc/kubernetes/admin.conf into your local ~/.kube/config. Check:
```
$ k config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```

### Try simply changing server ip in config

Try to change server address, to connect to remove:
```
$ vim ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    # server: https://10.128.0.16:6443
    server: https://158.160.61.136:6443
```

But this fails because admin certs are for 10.x.x.x ip, not for the public static ip:
```
$ k get nodes
E0317 20:39:56.908769  138241 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://158.160.61.136:6443/api?timeout=32s\": tls: failed to verify certificate: x509: certificate is valid for 10.255.0.1, 10.128.0.16, not 158.160.61.136"
Unable to connect to the server: tls: failed to verify certificate: x509: certificate is valid for 10.255.0.1, 10.128.0.16, not 158.160.61.136
```

### Try tunnelling localhost to remote via ssh

Change the server ip back to original /etc/kubernetes/admin.conf:
```
$ vim ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    server: https://10.128.0.16:6443
    # server: https://158.160.61.136:6443
```

Add kubernetes master ip 10.128.0.16 to localhost interface and verify:
```
$ sudo ip addr add 10.128.0.16/32 dev lo

$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.128.0.16/32 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever

$ ping 10.128.0.16   
PING 10.128.0.16 (10.128.0.16) 56(84) bytes of data.
64 bytes from 10.128.0.16: icmp_seq=1 ttl=64 time=0.053 ms
64 bytes from 10.128.0.16: icmp_seq=2 ttl=64 time=0.072 ms
64 bytes from 10.128.0.16: icmp_seq=3 ttl=64 time=0.069 ms

--- 10.128.0.16 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2026ms
rtt min/avg/max/mdev = 0.053/0.064/0.072/0.008 ms
```

Add entry for ssh tunnel to remote, MUST SPECIFY THE 10.128.0.16 IP in LocalForward statement:
```
$ vim ~/.ssh/config
Host k8s-training-master-tunnel
  HostName 158.160.61.136
  Port 22
  User artem
  # tunnel from self port 6443 to remote port 6443
  LocalForward 10.128.0.16:6443 6443
  ExitOnForwardFailure yes
  SessionType none
  ServerAliveInterval 60
  IdentityFile ~/.ssh/id_rsa
```


Now run tunnel and try to get nodes and check with curl using the master's ip:
```
$ sudo ss -lntp
State             Recv-Q            Send-Q                       Local Address:Port                       Peer Address:Port           Process
LISTEN            0                 4096                            127.0.0.54:53                              0.0.0.0:*               users:(("systemd-resolve",pid=293726,fd=21))
LISTEN            0                 4096                         127.0.0.53%lo:53                              0.0.0.0:*               users:(("systemd-resolve",pid=293726,fd=19))


$ ssh -v k8s-training-master-tunnel
debug1: Connecting to 158.160.61.136 [158.160.61.136] port 22.
...
Authenticated to 158.160.61.136 ([158.160.61.136]:22) using "publickey".
debug1: Local connections to 10.128.0.16:6443 forwarded to remote address 127.0.0.1:6443
debug1: Local forwarding listening on 10.128.0.16 port 6443.
...
debug1: Connection to port 6443 forwarding to 127.0.0.1 port 6443 requested.
debug1: channel 1: new direct-tcpip [direct-tcpip] (inactive timeout: 0)
debug1: channel 1: free: direct-tcpip: listening port 6443 for 127.0.0.1 port 6443, connect from 10.128.0.16 port 38922 to 10.128.0.16 port 6443, nchannels 2


$ sudo ss -lntp
State                Recv-Q               Send-Q                              Local Address:Port                               Peer Address:Port               Process
LISTEN               0                    4096                                   127.0.0.54:53                                      0.0.0.0:*                   users:(("systemd-resolve",pid=293726,fd=21))
LISTEN               0                    128                                   10.128.0.16:6443                                    0.0.0.0:*                   users:(("ssh",pid=643839,fd=4))
LISTEN               0                    4096                                127.0.0.53%lo:53                                      0.0.0.0:*                   users:(("systemd-resolve",pid=293726,fd=19))

$ curl -k https://10.128.0.16:6443
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```


Finally it works:
```
$ k get nodes
NAME      STATUS   ROLES           AGE     VERSION
master    Ready    control-plane   54d     v1.32.1
worker1   Ready    <none>          53d     v1.32.1
worker2   Ready    <none>          4d17h   v1.32.1
worker3   Ready    <none>          4d17h   v1.32.1
```

And now its possible to port-forward remote services to local machine.


# Extra: configure TLS in cluster

Interesting links:
- https://github.com/k3s-io/k3s/issues/6102#issuecomment-1238922182
- https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/
- https://github.com/open-telemetry/opentelemetry-helm-charts/pull/1034#discussion_r1489002563

I supplied cert info in kubelet join command, however this is not the end of certificate setup.
It seems that kubelet certs are not fully configured as e.g. metrics-server and otel collector encounter errors like the following when trying to scrape kubelet port 10250 metrics:
```
2025-03-27T16:34:08.366Z	error	scraperhelper@v0.121.0/obs_metrics.go:61	Error scraping metrics	{"otelcol.component.id": "kubeletstats", "otelcol.component.kind": "Receiver", "otelcol.signal": "metrics", "error": "Get \"https://10.128.0.25:10250/stats/summary\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.25 because it doesn't contain any IP SANs"}
```

The error is specifically about SAN = X509v3 Subject Alternative Name

### Examine current cluster certs

For reference here is formatted kube-api-server start command (tls args are there!):
```
root@master:~# ps axuf | grep api
root        1305  3.1  5.6 1659212 456976 ?      Ssl  13:26   7:17  \_ kube-apiserver 
    --advertise-address=10.128.0.16 
    --allow-privileged=true 
    --authorization-mode=Node,RBAC 
    --client-ca-file=/etc/kubernetes/pki/ca.crt 
    --enable-admission-plugins=NodeRestriction 
    --enable-bootstrap-token-auth=true 
    --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt 
    --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt 
    --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key 
    --etcd-servers=https://127.0.0.1:2379 
    --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt 
    --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key 
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname 
    --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt 
    --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key 
    --requestheader-allowed-names=front-proxy-client 
    --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt 
    --requestheader-extra-headers-prefix=X-Remote-Extra- 
    --requestheader-group-headers=X-Remote-Group 
    --requestheader-username-headers=X-Remote-User 
    --secure-port=6443 
    --service-account-issuer=https://kubernetes.default.svc.cluster.local 
    --service-account-key-file=/etc/kubernetes/pki/sa.pub 
    --service-account-signing-key-file=/etc/kubernetes/pki/sa.key 
    --service-cluster-ip-range=10.255.0.0/16 
    --tls-cert-file=/etc/kubernetes/pki/apiserver.crt 
    --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
```

Start by examining certificates on master node, first the certificate for cluster and the certificate for kubelet running on master:
```
oot@master:~# ls -la /etc/kubernetes/pki
total 68
drwxr-xr-x 3 root root 4096 Jan 26 07:23 .
drwxrwxr-x 5 root root 4096 Feb 25 20:57 ..
-rw-r--r-- 1 root root 1281 Jan 26 23:48 apiserver.crt
-rw-r--r-- 1 root root 1123 Jan 26 23:48 apiserver-etcd-client.crt
-rw------- 1 root root 1675 Jan 26 23:48 apiserver-etcd-client.key
-rw------- 1 root root 1675 Jan 26 23:48 apiserver.key
-rw-r--r-- 1 root root 1176 Jan 26 23:48 apiserver-kubelet-client.crt
-rw------- 1 root root 1679 Jan 26 23:48 apiserver-kubelet-client.key
-rw-r--r-- 1 root root 1107 Jan 26 07:23 ca.crt
-rw------- 1 root root 1679 Jan 26 07:23 ca.key
drwxr-xr-x 2 root root 4096 Jan 26 07:23 etcd
-rw-r--r-- 1 root root 1123 Jan 26 07:23 front-proxy-ca.crt
-rw------- 1 root root 1679 Jan 26 07:23 front-proxy-ca.key
-rw-r--r-- 1 root root 1119 Jan 26 23:48 front-proxy-client.crt
-rw------- 1 root root 1679 Jan 26 23:48 front-proxy-client.key
-rw------- 1 root root 1679 Jan 26 07:23 sa.key
-rw------- 1 root root  451 Jan 26 07:23 sa.pub

root@master:~# openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4380387176016264521 (0x3cca42eda5203d49)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Jan 26 23:39:35 2025 GMT
            Not After : Jan 26 23:44:35 2026 GMT
        Subject: CN = kube-apiserver
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:b5:70:fc:b4:b9:7f:31:81:0d:e5:83:e9:71:b6:
                    ...
                    db:cf:1e:3a:4a:26:7e:3a:32:00:67:23:2d:ff:e1:
                    ee:9b:bd:e0:a0:17:d0:3d:96:9d:14:d0:30:f4:9c:
                    20:79:54:a7:31:ea:18:f1:a7:e5:ba:5f:55:93:4c:
                    3e:4f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                A8:9C:D9:52:58:C7:51:03:69:0B:FD:72:19:C6:AC:0D:F8:FF:81:EE
            X509v3 Subject Alternative Name: 
                DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP Address:10.255.0.1, IP Address:10.128.0.16
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        50:50:6d:e8:ae:63:7f:a1:42:c5:a3:58:a2:53:d8:60:23:b7:
        ...
        db:cf:1e:3a:4a:26:7e:3a:32:00:67:23:2d:ff:e1:
        ee:9b:bd:e0:a0:17:d0:3d:96:9d:14:d0:30:f4:9c:
        3a:ad:b8:61


root@master:~# ls -l /var/lib/kubelet/pki
total 12
-rw------- 1 root root 2822 Jan 26 07:23 kubelet-client-2025-01-26-07-23-33.pem
lrwxrwxrwx 1 root root   59 Jan 26 07:23 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2025-01-26-07-23-33.pem
-rw-r--r-- 1 root root 2254 Jan 26 07:23 kubelet.crt
-rw------- 1 root root 1679 Jan 26 07:23 kubelet.key

root@master:~# openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 3798245667035869957 (0x34b6144f6956f305)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = master-ca@1737876213
        Validity
            Not Before: Jan 26 06:23:33 2025 GMT
            Not After : Jan 26 06:23:33 2026 GMT
        Subject: CN = master@1737876213
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:eb:8b:ec:11:96:ce:ad:ab:44:24:60:ea:76:e3:
                    f9:4a:e8:b9:67:78:8a:8f:82:07:3b:70:e9:cf:60:
                    ...
                    7e:eb:33:72:2c:85:9c:d9:90:4f:a5:2d:87:79:23:
                    69:66:e2:0e:d4:32:d0:88:41:46:28:3d:3c:55:f4:
                    c8:a3
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                E9:1F:24:46:9B:D4:35:8C:8A:C7:C2:4B:FD:17:63:E7:40:5C:E0:C3
            X509v3 Subject Alternative Name: 
                DNS:master
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        ab:a6:9f:24:1e:8b:b0:27:18:6d:ba:aa:51:9e:ee:1c:57:68:
        ...
        cc:1d:fa:f8:29:a4:be:a1:28:d0:bf:fe:42:85:36:18:af:d6:
        86:7a:fd:36
```

Well its clear that the kubelet on master does not have its ip address in SANs list (unlike the kubernetes admin server certificate above).
Most likely the same is true on worker nodes.
Hence requests to "https://10.128.0.25:10250/stats/summary" do not pass TLS.


Lets checkout the worker1 certificates for cluster server and for worker kubelet:
```

root@worker1:/# ls -la /etc/kubernetes/pki
total 12
drwxr-xr-x 2 root root 4096 Jan 26 20:55 .
drwxrwxr-x 5 root root 4096 Jan 27 00:02 ..
-rw-r--r-- 1 root root 1107 Jan 26 20:55 ca.crt

root@worker1:/# openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 8597161340887333357 (0x774f40b0984f79ed)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Jan 26 07:17:52 2025 GMT
            Not After : Jan 24 07:22:52 2035 GMT
        Subject: CN = kubernetes
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:e4:2d:a1:7a:13:99:e0:3c:c9:17:48:33:9f:a4:
                    22:31:25:26:1e:11:af:65:4f:a4:cd:36:d6:bd:af:
                    d6:05:9e:43:ab:c4:a1:57:7f:c7:fd:38:8a:a8:14:
                    ...
                    2f:0a:c4:b6:b4:f7:a9:99:13:e7:90:1c:a2:93:19:
                    04:5c:ad:45:2e:5c:fd:22:d3:8a:d1:78:50:6d:ed:
                    f7:3b
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier: 
                A8:9C:D9:52:58:C7:51:03:69:0B:FD:72:19:C6:AC:0D:F8:FF:81:EE
            X509v3 Subject Alternative Name: 
                DNS:kubernetes
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        79:70:60:84:5d:b3:fe:db:d9:77:6f:65:cf:7d:4b:16:fd:fb:
        b2:41:31:1e:ff:67:64:4d:ac:de:f3:cd:ca:ab:b9:1d:9c:b5:
        49:59:89:be:32:3c:e7:3e:57:1f:2a:ce:b9:fb:14:37:30:40:
        ...
        22:e3:2c:60:58:b6:5a:87:0d:20:46:67:74:62:0e:5d:63:b0:
        98:08:5d:49


root@worker1:/var/lib/kubelet/pki# ls -la
total 20
drwxr-xr-x 2 root root 4096 Jan 26 20:55 .
drwxrwxr-x 9 root root 4096 Jan 27 00:03 ..
-rw------- 1 root root 1110 Jan 26 20:55 kubelet-client-2025-01-26-20-55-16.pem
lrwxrwxrwx 1 root root   59 Jan 26 20:55 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2025-01-26-20-55-16.pem
-rw-r--r-- 1 root root 2262 Jan 26 20:55 kubelet.crt
-rw------- 1 root root 1675 Jan 26 20:55 kubelet.key

root@worker1:/var/lib/kubelet/pki# openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 7205592585443665118 (0x63ff6847938ee4de)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = worker1-ca@1737924916
        Validity
            Not Before: Jan 26 19:55:16 2025 GMT
            Not After : Jan 26 19:55:16 2026 GMT
        Subject: CN = worker1@1737924916
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d0:51:91:63:a5:12:eb:d5:98:62:b7:2f:96:bd:
                    ...
                    b8:42:e7:1f:e1:2f:5a:51:29:36:44:20:b3:ab:6a:
                    13:19:aa:bb:95:10:f9:43:ab:d6:04:dc:84:98:bb:
                    49:49
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                5F:04:EC:64:02:88:3C:B1:86:AA:6D:BB:68:91:15:CF:ED:AC:4C:C6
            X509v3 Subject Alternative Name: 
                DNS:worker1
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        2f:ec:c7:38:25:a5:a4:22:48:6e:2b:3a:73:cd:82:52:29:da:
        17:04:eb:11:f0:a5:5a:2c:43:4e:e1:d8:fb:31:4f:5d:58:61:
        ...
        12:05:e6:fd:22:6a:d0:0e:7a:4e:15:a6:c1:c3:09:e0:7a:b4:
        fb:fa:0c:45
```


Also look at cert that kubelet uses to authenticate TO the api server:
```
root@worker1:/# openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            bd:fa:c4:35:ac:1b:06:58:f2:ba:d8:1b:ae:3c:c8:c7
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Jan 26 20:50:16 2025 GMT
            Not After : Jan 26 20:50:16 2026 GMT
        Subject: O = system:nodes, CN = system:node:worker1
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:4d:2c:74:90:0d:9f:69:1c:53:9a:54:62:46:16:
                    32:de:fc:12:3f:1e:dd:a6:0a:fd:80:61:d2:7a:e5:
                    79:c5:e7:fe:77:59:a0:34:d2:fd:f1:74:09:09:e6:
                    b0:b6:3e:93:5c:29:b9:aa:3d:52:35:b7:db:9f:75:
                    e3:f5:25:e2:a3
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                A8:9C:D9:52:58:C7:51:03:69:0B:FD:72:19:C6:AC:0D:F8:FF:81:EE
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        6e:df:d0:c4:d7:0c:d6:3d:b9:32:d9:ee:a6:fd:0c:10:94:d0:
        ...
        31:e3:50:ce:c9:48:83:2c:fc:56:98:bb:ba:49:e4:2e:22:3c:
```

Can checkout worker1 node kubelet config via api:
```
$ kubectl get --raw "/api/v1/nodes/worker1/proxy/configz" | jq
{
  "kubeletconfig": {
    "enableServer": true,
    "staticPodPath": "/etc/kubernetes/manifests",
    "podLogsDir": "/var/log/pods",
    "syncFrequency": "1m0s",
    "fileCheckFrequency": "20s",
    "httpCheckFrequency": "20s",
    "address": "0.0.0.0",
    "port": 10250,
    "tlsCertFile": "/var/lib/kubelet/pki/kubelet.crt",
    "tlsPrivateKeyFile": "/var/lib/kubelet/pki/kubelet.key",
    "rotateCertificates": true,
    "authentication": {
      "x509": {
        "clientCAFile": "/etc/kubernetes/pki/ca.crt"
      },
      "webhook": {
        "enabled": true,
        "cacheTTL": "2m0s"
      },
      "anonymous": {
        "enabled": false
      }
    },
    "authorization": {
      "mode": "Webhook",
      "webhook": {
        "cacheAuthorizedTTL": "5m0s",
        "cacheUnauthorizedTTL": "30s"
      }
    },
    "registryPullQPS": 5,
    "registryBurst": 10,
    "eventRecordQPS": 50,
    "eventBurst": 100,
    "enableDebuggingHandlers": true,
    "healthzPort": 10248,
    "healthzBindAddress": "127.0.0.1",
    "oomScoreAdj": -999,
    "clusterDomain": "cluster.local",
    "clusterDNS": [
      "10.255.0.10"
    ],
    "streamingConnectionIdleTimeout": "4h0m0s",
    "nodeStatusUpdateFrequency": "10s",
    "nodeStatusReportFrequency": "5m0s",
    "nodeLeaseDurationSeconds": 40,
    "imageMinimumGCAge": "2m0s",
    "imageMaximumGCAge": "0s",
    "imageGCHighThresholdPercent": 85,
    "imageGCLowThresholdPercent": 80,
    "volumeStatsAggPeriod": "1m0s",
    "cgroupsPerQOS": true,
    "cgroupDriver": "systemd",
    "cpuManagerPolicy": "none",
    "cpuManagerReconcilePeriod": "10s",
    "memoryManagerPolicy": "None",
    "topologyManagerPolicy": "none",
    "topologyManagerScope": "container",
    "runtimeRequestTimeout": "2m0s",
    "hairpinMode": "promiscuous-bridge",
    "maxPods": 110,
    "podPidsLimit": -1,
    "resolvConf": "/etc/resolv.conf",
    "cpuCFSQuota": true,
    "cpuCFSQuotaPeriod": "100ms",
    "nodeStatusMaxImages": 50,
    "maxOpenFiles": 1000000,
    "contentType": "application/vnd.kubernetes.protobuf",
    "kubeAPIQPS": 50,
    "kubeAPIBurst": 100,
    "serializeImagePulls": true,
    "evictionHard": {
      "imagefs.available": "15%",
      "imagefs.inodesFree": "5%",
      "memory.available": "100Mi",
      "nodefs.available": "10%",
      "nodefs.inodesFree": "5%"
    },
    "evictionPressureTransitionPeriod": "5m0s",
    "enableControllerAttachDetach": true,
    "makeIPTablesUtilChains": true,
    "iptablesMasqueradeBit": 14,
    "iptablesDropBit": 15,
    "failSwapOn": true,
    "memorySwap": {},
    "containerLogMaxSize": "10Mi",
    "containerLogMaxFiles": 5,
    "containerLogMaxWorkers": 1,
    "containerLogMonitorInterval": "10s",
    "configMapAndSecretChangeDetectionStrategy": "Watch",
    "enforceNodeAllocatable": [
      "pods"
    ],
    "volumePluginDir": "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/",
    "logging": {
      "format": "text",
      "flushFrequency": "5s",
      "verbosity": 0,
      "options": {
        "text": {
          "infoBufferSize": "0"
        },
        "json": {
          "infoBufferSize": "0"
        }
      }
    },
    "enableSystemLogHandler": true,
    "enableSystemLogQuery": false,
    "shutdownGracePeriod": "0s",
    "shutdownGracePeriodCriticalPods": "0s",
    "crashLoopBackOff": {},
    "enableProfilingHandler": true,
    "enableDebugFlagsHandler": true,
    "seccompDefault": false,
    "memoryThrottlingFactor": 0.9,
    "registerNode": true,
    "localStorageCapacityIsolation": true,
    "containerRuntimeEndpoint": "unix:///var/run/cri-dockerd.sock",
    "failCgroupV1": false
  }
}
```

Also can check node kubelet config on filesystem. Check two certificate settings:
```
root@worker1:/# cat /var/lib/kubelet/config.yaml | grep rotateCertificates
rotateCertificates: true

root@worker1:/# cat /var/lib/kubelet/config.yaml | grep serverTLSBootstrap
root@worker1:/#
```

rotateCertificates: true handles the client cert (for kubelet to talk to the API Server).
serverTLSBootstrap: true handles the server cert (for scraping metrics on the kubelet by IP or DNS name).


### Resolve issue with bad kubelet server certificate

At this point found documentation addressing exactly this problem with kubelet server-cert:
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#kubelet-serving-certs

Update /root/kubeadm-config.yaml to have `serverTLSBootstrap: true` on one of the nodes (e.g. on master):
```
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
serverTLSBootstrap: true
```

This time its not possible to use IaC via kubeadm, as ConfigMap will not get updated (I tried it with something like "kubeadm init phase kubelet-start --config /root/kubeadm-config.yaml").
Must manually update config map and each kubelet config and restart it, just as documentation says.

Another doc on how to update kubelet config: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#applying-kubelet-configuration-changes

Added "serverTLSBootstrap: true" next to "rotateCertificates: true":
```
$ k edit cm -n kube-system kubelet-config
apiVersion: v1
data:
  kubelet: |
    apiVersion: kubelet.config.k8s.io/v1beta1
    authentication:
      anonymous:
        enabled: false
      webhook:
        cacheTTL: 0s
        enabled: true
      x509:
        clientCAFile: /etc/kubernetes/pki/ca.crt
    authorization:
      mode: Webhook
      webhook:
        cacheAuthorizedTTL: 0s
        cacheUnauthorizedTTL: 0s
    cgroupDriver: systemd
    clusterDNS:
    - 10.255.0.10
    clusterDomain: cluster.local
    containerRuntimeEndpoint: ""
    cpuManagerReconcilePeriod: 0s
    crashLoopBackOff: {}
    evictionPressureTransitionPeriod: 0s
    fileCheckFrequency: 0s
    healthzBindAddress: 127.0.0.1
    healthzPort: 10248
    httpCheckFrequency: 0s
    imageMaximumGCAge: 0s
    imageMinimumGCAge: 0s
    kind: KubeletConfiguration
    logging:
      flushFrequency: 0
      options:
        json:
          infoBufferSize: "0"
        text:
          infoBufferSize: "0"
      verbosity: 0
    memorySwap: {}
    nodeStatusReportFrequency: 0s
    nodeStatusUpdateFrequency: 0s
    rotateCertificates: true
    serverTLSBootstrap: true
    runtimeRequestTimeout: 0s
    shutdownGracePeriod: 0s
    shutdownGracePeriodCriticalPods: 0s
    staticPodPath: /etc/kubernetes/manifests
    streamingConnectionIdleTimeout: 0s
    syncFrequency: 0s
    volumeStatsAggPeriod: 0s
kind: ConfigMap
metadata:
  creationTimestamp: "2025-01-26T07:24:04Z"
  name: kubelet-config
  namespace: kube-system
  resourceVersion: "26567"
  uid: 35ca2358-253b-4f2b-a89e-afb2cd9a2f84


root@master:~# systemctl restart kubelet
```


Verify changes:
```
root@master:~# cat /var/lib/kubelet/config.yaml | grep serverTLSBootstrap
serverTLSBootstrap: true

$ kubectl get --raw "/api/v1/nodes/master/proxy/configz" | jq | rg serverTLSBootstrap
Error from server (ServiceUnavailable): error trying to reach service: remote error: tls: internal error

$ kubectl get --raw "/api/v1/nodes/worker1/proxy/configz" | jq | rg serverTLSBootstrap
$

$ kubectl get --raw "/api/v1/nodes/worker2/proxy/configz" | jq | head
{
  "kubeletconfig": {
    "enableServer": true,
    "staticPodPath": "/etc/kubernetes/manifests",
    "podLogsDir": "/var/log/pods",
    "syncFrequency": "1m0s",
    "fileCheckFrequency": "20s",
    "httpCheckFrequency": "20s",
    "address": "0.0.0.0",
    "port": 10250,
```

Something is suspicious. The worker1 and worker2 and worker3 kubelet configs did not change, and I can retrieve them.
The master config clearly changed, but now I can not retrieve it via api. At this point I tried rebooting the master server, it did not help.

```
root@master:/var/lib/kubelet# systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Thu 2025-03-27 19:35:10 UTC; 8min ago
       Docs: https://kubernetes.io/docs/
   Main PID: 916 (kubelet)
      Tasks: 12 (limit: 9482)
     Memory: 47.1M
        CPU: 8.626s
     CGroup: /system.slice/kubelet.service
             └─916 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=>

Mar 27 19:39:20 master kubelet[916]: I0327 19:39:20.552419     916 ???:1] "http: TLS handshake error from 10.128.0.16:47386: no serving certificate available for the kubelet"
Mar 27 19:39:26 master kubelet[916]: I0327 19:39:26.549884     916 ???:1] "http: TLS handshake error from 10.128.0.16:41474: no serving certificate available for the kubelet"
Mar 27 19:40:20 master kubelet[916]: I0327 19:40:20.554093     916 ???:1] "http: TLS handshake error from 10.128.0.16:45042: no serving certificate available for the kubelet"
Mar 27 19:40:26 master kubelet[916]: I0327 19:40:26.550955     916 ???:1] "http: TLS handshake error from 10.128.0.16:44406: no serving certificate available for the kubelet"
Mar 27 19:41:20 master kubelet[916]: I0327 19:41:20.553599     916 ???:1] "http: TLS handshake error from 10.128.0.16:45880: no serving certificate available for the kubelet"
Mar 27 19:41:26 master kubelet[916]: I0327 19:41:26.550346     916 ???:1] "http: TLS handshake error from 10.128.0.16:44832: no serving certificate available for the kubelet"
Mar 27 19:42:20 master kubelet[916]: I0327 19:42:20.553146     916 ???:1] "http: TLS handshake error from 10.128.0.16:48594: no serving certificate available for the kubelet"
Mar 27 19:42:26 master kubelet[916]: I0327 19:42:26.550228     916 ???:1] "http: TLS handshake error from 10.128.0.16:45812: no serving certificate available for the kubelet"
Mar 27 19:43:20 master kubelet[916]: I0327 19:43:20.552743     916 ???:1] "http: TLS handshake error from 10.128.0.16:49312: no serving certificate available for the kubelet"
Mar 27 19:43:26 master kubelet[916]: I0327 19:43:26.550215     916 ???:1] "http: TLS handshake error from 10.128.0.16:56920: no serving certificate available for the kubelet"
```

Here I realised that kubelet now does not have a self-signed cert, but gets one from api server, which I must manually approve (there are two CSRs because a new request was put up after reboot I guess):
```
root@master:~# k get csr
NAME        AGE     SIGNERNAME                      REQUESTOR            REQUESTEDDURATION   CONDITION
csr-gw8kw   9m30s   kubernetes.io/kubelet-serving   system:node:master   <none>              Pending
csr-lfdwj   18m     kubernetes.io/kubelet-serving   system:node:master   <none>              Pending

root@master:~# k certificate approve csr-gw8kw
certificatesigningrequest.certificates.k8s.io/csr-gw8kw approved

root@master:~# k get csr
NAME        AGE   SIGNERNAME                      REQUESTOR            REQUESTEDDURATION   CONDITION
csr-gw8kw   13m   kubernetes.io/kubelet-serving   system:node:master   <none>              Approved,Issued
csr-lfdwj   23m   kubernetes.io/kubelet-serving   system:node:master   <none>              Pending

root@master:~# kubectl get --raw "/api/v1/nodes/master/proxy/stats/summary"  | head
{
 "node": {
  "nodeName": "master",
  "systemContainers": [
   {
    "name": "kubelet",
    "startTime": "2025-03-27T19:35:10Z",
    "cpu": {
     "time": "2025-03-27T19:48:25Z",
     "usageNanoCores": 19116220,


root@master:~# kubectl get --raw "/api/v1/nodes/master/proxy/configz"  | jq
{
  "kubeletconfig": {
    "enableServer": true,
    "staticPodPath": "/etc/kubernetes/manifests",
    "podLogsDir": "/var/log/pods",
    "syncFrequency": "1m0s",
    "fileCheckFrequency": "20s",
    "httpCheckFrequency": "20s",
    "address": "0.0.0.0",
    "port": 10250,
    "rotateCertificates": true,
    "serverTLSBootstrap": true,
    "authentication": {
      "x509": {
        "clientCAFile": "/etc/kubernetes/pki/ca.crt"
      },
      "webhook": {
        "enabled": true,
        "cacheTTL": "2m0s"
      },
      "anonymous": {
        "enabled": false
      }
    },
    "authorization": {
      "mode": "Webhook",
      "webhook": {
        "cacheAuthorizedTTL": "5m0s",
        "cacheUnauthorizedTTL": "30s"
      }
    },
    "registryPullQPS": 5,
    "registryBurst": 10,
    "eventRecordQPS": 50,
    "eventBurst": 100,
    "enableDebuggingHandlers": true,
    "healthzPort": 10248,
    "healthzBindAddress": "127.0.0.1",
    "oomScoreAdj": -999,
    "clusterDomain": "cluster.local",
    "clusterDNS": [
      "10.255.0.10"
    ],
    "streamingConnectionIdleTimeout": "4h0m0s",
    "nodeStatusUpdateFrequency": "10s",
    "nodeStatusReportFrequency": "5m0s",
    "nodeLeaseDurationSeconds": 40,
    "imageMinimumGCAge": "2m0s",
    "imageMaximumGCAge": "0s",
    "imageGCHighThresholdPercent": 85,
    "imageGCLowThresholdPercent": 80,
    "volumeStatsAggPeriod": "1m0s",
    "cgroupsPerQOS": true,
    "cgroupDriver": "systemd",
    "cpuManagerPolicy": "none",
    "cpuManagerReconcilePeriod": "10s",
    "memoryManagerPolicy": "None",
    "topologyManagerPolicy": "none",
    "topologyManagerScope": "container",
    "runtimeRequestTimeout": "2m0s",
    "hairpinMode": "promiscuous-bridge",
    "maxPods": 110,
    "podPidsLimit": -1,
    "resolvConf": "/etc/resolv.conf",
    "cpuCFSQuota": true,
    "cpuCFSQuotaPeriod": "100ms",
    "nodeStatusMaxImages": 50,
    "maxOpenFiles": 1000000,
    "contentType": "application/vnd.kubernetes.protobuf",
    "kubeAPIQPS": 50,
    "kubeAPIBurst": 100,
    "serializeImagePulls": true,
    "evictionHard": {
      "imagefs.available": "15%",
      "imagefs.inodesFree": "5%",
      "memory.available": "100Mi",
      "nodefs.available": "10%",
      "nodefs.inodesFree": "5%"
    },
    "evictionPressureTransitionPeriod": "5m0s",
    "enableControllerAttachDetach": true,
    "makeIPTablesUtilChains": true,
    "iptablesMasqueradeBit": 14,
    "iptablesDropBit": 15,
    "failSwapOn": true,
    "memorySwap": {},
    "containerLogMaxSize": "10Mi",
    "containerLogMaxFiles": 5,
    "containerLogMaxWorkers": 1,
    "containerLogMonitorInterval": "10s",
    "configMapAndSecretChangeDetectionStrategy": "Watch",
    "enforceNodeAllocatable": [
      "pods"
    ],
    "volumePluginDir": "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/",
    "logging": {
      "format": "text",
      "flushFrequency": "5s",
      "verbosity": 0,
      "options": {
        "text": {
          "infoBufferSize": "0"
        },
        "json": {
          "infoBufferSize": "0"
        }
      }
    },
    "enableSystemLogHandler": true,
    "enableSystemLogQuery": false,
    "shutdownGracePeriod": "0s",
    "shutdownGracePeriodCriticalPods": "0s",
    "crashLoopBackOff": {},
    "enableProfilingHandler": true,
    "enableDebugFlagsHandler": true,
    "seccompDefault": false,
    "memoryThrottlingFactor": 0.9,
    "registerNode": true,
    "localStorageCapacityIsolation": true,
    "containerRuntimeEndpoint": "unix:///var/run/cri-dockerd.sock",
    "failCgroupV1": false
  }
}

root@master:~# k certificate deny csr-lfdwj
certificatesigningrequest.certificates.k8s.io/csr-lfdwj denied

root@master:~# k get csr
NAME        AGE   SIGNERNAME                      REQUESTOR            REQUESTEDDURATION   CONDITION
csr-gw8kw   14m   kubernetes.io/kubelet-serving   system:node:master   <none>              Approved,Issued
csr-lfdwj   24m   kubernetes.io/kubelet-serving   system:node:master   <none>              Denied
```

Now everything works, delete the other CSR and lets check out the new kubelet certs:
```
root@master:~# ls -la /var/lib/kubelet/pki/
total 24
drwxr-xr-x 2 root root 4096 Mar 27 19:47 .
drwxrwxr-x 9 root root 4096 Mar 27 19:38 ..
-rw------- 1 root root 2822 Jan 26 07:23 kubelet-client-2025-01-26-07-23-33.pem
lrwxrwxrwx 1 root root   59 Jan 26 07:23 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2025-01-26-07-23-33.pem
-rw-r--r-- 1 root root 2254 Jan 26 07:23 kubelet.crt
-rw------- 1 root root 1679 Jan 26 07:23 kubelet.key
-rw------- 1 root root 1143 Mar 27 19:47 kubelet-server-2025-03-27-19-47-43.pem
lrwxrwxrwx 1 root root   59 Mar 27 19:47 kubelet-server-current.pem -> /var/lib/kubelet/pki/kubelet-server-2025-03-27-19-47-43.pem

root@master:~# openssl x509 -in /var/lib/kubelet/pki/kubelet-server-current.pem -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            dc:5c:d7:af:07:60:c2:e2:b3:a9:47:57:4d:88:54:c0
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Mar 27 19:42:43 2025 GMT
            Not After : Mar 27 19:42:43 2026 GMT
        Subject: O = system:nodes, CN = system:node:master
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:e7:4a:34:0a:24:57:7f:94:1f:7d:01:fe:52:49:
                    ab:29:d5:d6:5b:33:01:d9:57:a0:08:63:8b:bf:fa:
                    c1:cd:5e:57:b6:ae:a3:71:aa:f7:3e:c0:3a:99:9c:
                    62:28:f0:87:5a:64:1b:20:e0:47:64:c1:9d:9a:91:
                    d5:67:9c:6c:b0
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                A8:9C:D9:52:58:C7:51:03:69:0B:FD:72:19:C6:AC:0D:F8:FF:81:EE
            X509v3 Subject Alternative Name: 
                DNS:master, IP Address:10.128.0.16
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        c1:88:d8:e9:38:7a:7f:93:86:ad:71:d1:92:f7:d2:57:2f:e6:
        ...
        a2:a5:f7:45:cc:49:e9:e0:d5:cc:ba:d2:45:fb:e5:e2:69:2b:
```

There is a new cert added called kubelet-server-current.pem, which supposedly is the new kubelet server certificate which is Issued by same CN as cluster api cert.
And it has IP Address under SAN = Subject Alternative Name.


Now do the same on other worker nodes:
```
$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1

root@worker1:~# cat /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 10.255.0.10
clusterDomain: cluster.local
containerRuntimeEndpoint: ""
cpuManagerReconcilePeriod: 0s
crashLoopBackOff: {}
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMaximumGCAge: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
    text:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
serverTLSBootstrap: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s


root@worker1:~# systemctl restart kubelet

$ k get --raw "/api/v1/nodes/worker1/proxy/configz" | jq | rg serverTLSBootstrap
Error from server (ServiceUnavailable): error trying to reach service: remote error: tls: internal error

$ k get csr
NAME        AGE   SIGNERNAME                      REQUESTOR             REQUESTEDDURATION   CONDITION
csr-gw8kw   44m   kubernetes.io/kubelet-serving   system:node:master    <none>              Approved,Issued
csr-kc259   2s    kubernetes.io/kubelet-serving   system:node:worker1   <none>              Pending
csr-lfdwj   53m   kubernetes.io/kubelet-serving   system:node:master    <none>              Denied

$ k certificate approve csr-kc259
certificatesigningrequest.certificates.k8s.io/csr-kc259 approved

$ k get csr
NAME        AGE    SIGNERNAME                      REQUESTOR             REQUESTEDDURATION   CONDITION
csr-gw8kw   46m    kubernetes.io/kubelet-serving   system:node:master    <none>              Approved,Issued
csr-kc259   2m1s   kubernetes.io/kubelet-serving   system:node:worker1   <none>              Approved,Issued
csr-lfdwj   55m    kubernetes.io/kubelet-serving   system:node:master    <none>              Denied

$ k get --raw "/api/v1/nodes/worker1/proxy/configz" | jq | rg serverTLSBootstrap
    "serverTLSBootstrap": true,
```


Finally each worker has been approved for 1 year and will need to be re-approved manually:
```
$ k get csr
NAME        AGE     SIGNERNAME                      REQUESTOR             REQUESTEDDURATION   CONDITION
csr-gw8kw   51m     kubernetes.io/kubelet-serving   system:node:master    <none>              Approved,Issued
csr-jgsm6   49s     kubernetes.io/kubelet-serving   system:node:worker3   <none>              Approved,Issued
csr-kc259   7m21s   kubernetes.io/kubelet-serving   system:node:worker1   <none>              Approved,Issued
csr-lfdwj   61m     kubernetes.io/kubelet-serving   system:node:master    <none>              Denied
csr-qm8z9   2m9s    kubernetes.io/kubelet-serving   system:node:worker2   <none>              Approved,Issued
```

### Optionally auto-approve kubelet Certificate Signing Requests to renew kubelet-server-current.pem in 1 year

Optionally add deployment to auto-approve such CSRs:
- https://github.com/postfinance/kubelet-csr-approver
- https://github.com/kontena/kubelet-rubber-stamp
- home script to run at worker init for automation https://www.reddit.com/r/kubernetes/comments/1028mw3/kubeadm_join_add_ip_sans_to_kubelet/

Script:
```
export NODE_NAME=your_node_name
for csr in $(kubectl get csr -o yaml | 
    yq '.items[] | 
            select( .spec.username=="system:node:" + env(NODE_NAME) and 
                    ( 
                        ( has("status.conditions") | not ) or 
                        (.status.conditions[] | select(.type=="Approved") | length)==0
                    )
                ) | .metadata.name');
do
    kubectl certificate approve $csr
done
```

But there are security reasons why automatic is off by default (rogue node joins cluster and advertises that its available for sensitive workloads):
- https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#certificate-rotation
- https://github.com/kubernetes/community/pull/1982/files?short_path=90a9845#diff-90a984514dd39c69615f0a9bc3409ec72809abe7c298924ed89d29dc7d34a18a
- https://github.com/kubernetes-sigs/kubespray/pull/6453#discussion_r466320173
