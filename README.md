# k8s-training

# Buy VMs
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
```

List/Start/Stop instances:
```
# yc compute instances list
# yc compute instances start master & yc compute instances start worker1 & yc compute instances start worker2 & yc compute instances start worker3
# yc compute instances stop master & yc compute instances stop worker1 & yc compute instances stop worker2 & yc compute instances stop worker3
```


# Prepare them (see: https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

Enable packet forwarding:
sysctl params required by setup, params persist across reboots
```
# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# sudo sysctl --system
```

# Install CRI (container)

Update vm and install docker from repos

```
# sudo apt update
# sudo apt upgrade
# sudo apt install docker.io
```

Install docker shim for cri integration (see https://mirantis.github.io/cri-dockerd/usage/install/) on debian 11 bullseye:
```
# wget 'https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.16/cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb' -o cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
# sudo dpkg -i cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
```

# Install CNI (network)

Used instruction in flannel readme (https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually):
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

# Bootstrap cluster

Instruction from CRI-O repo (https://github.com/cri-o/packaging/blob/main/README.md#bootstrap-a-cluster-1)
Add kubernetes repository for 
- kubeadm
- kubelet
- kubectl
```
# curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list
```

Configure final vm params:
```
# swapoff -a
# modprobe br_netfilter
```

"br_netfilter" was already loaded by "bridge" kernel module. 

# kubeadm init
Finally master init, pass --pod-network-cird as flannel requests (https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md)
```
kubeadm init --pod-network-cidr=10.244.0.0/16

```
