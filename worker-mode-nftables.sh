cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system

apt update
apt upgrade -y

mkdir /etc/docker/
echo '{"iptables": false,"ip6tables": false}' > /etc/docker/daemon.json
apt install -y docker.io gpg ca-certificates
install -m 0755 -d /etc/apt/keyrings

wget --show-progress 'https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.16/cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb' -O cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb
dpkg -i cri-dockerd_0.3.16.3-0.debian-bullseye_amd64.deb

export KUBERNETES_VERSION=v1.31
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# flannel needs br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
systemctl restart systemd-modules-load.service

### above is the same for master/worker

# get join token: $ kubeadm token create --print-join-command

cat <<EOF | sudo tee /root/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
nodeRegistration:
  # name: worker1          # hostname by default
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
EOF

kubeadm join --config /root/kubeadm-config.yaml

