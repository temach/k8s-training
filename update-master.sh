vim /etc/apt/sources.list.d/kubernetes.list
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

apt update

apt-mark unhold kubeadm
apt install -y kubeadm
apt-mark hold kubeadm

kubeadm upgrade plan
kubeadm upgrade apply v1.32.1

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl drain master --ignore-daemonsets

apt-mark unhold kubelet kubectl && apt-get update && apt-get install -y kubelet kubectl && apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

kubectl uncordon master
