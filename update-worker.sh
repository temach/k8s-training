vim /etc/apt/sources.list.d//kubernetes.list 
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm && apt-mark hold kubeadm
kubeadm upgrade node

export KUBECONFIG=/etc/kubernetes/admin.conf  # on master node
kubectl drain worker1 --ignore-daemonsets   # on master node

apt-mark unhold kubelet kubectl && apt-get update && apt-get install -y kubelet kubectl && apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

kubectl uncordon worker1   # on master node
