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


