# k8s-training

# Install istio

### lecture live demo

Reference steps from lecture, see ./istio-k3d-demo.txt:
```
--------------------------
--- helm istio install ---
--------------------------

$ kubectl create ns istio-system

$ helm repo add istio https://istio-release.storage.googleapis.com/charts

$ helm repo update

$ helm install istio-base istio/base -n istio-system

$ helm install istiod istio/istiod -n istio-system --wait

$ kubectl get pod -n istio-system


-----------------------
--- manifests apply ---
-----------------------

$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/kiali.yaml

$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/prometheus.yaml

# change "type: ClusterIP" -> "type: NodePort"
$ kubectl edit svc kiali -n istio-system
```


### install istio

Create helmfile, must also get chart version numbers.

```
# helm repo add istio https://istio-release.storage.googleapis.com/charts

# helm search repo istio
NAME               	CHART VERSION	APP VERSION	DESCRIPTION                                       
istio/istiod       	1.25.0       	1.25.0     	Helm chart for istio control plane                
istio/istiod-remote	1.23.5       	1.23.5     	Helm chart for a remote cluster using an extern...
istio/ambient      	1.25.0       	1.25.0     	Helm umbrella chart for ambient                   
istio/base         	1.25.0       	1.25.0     	Helm chart for deploying Istio cluster resource...
istio/cni          	1.25.0       	1.25.0     	Helm chart for istio-cni components               
istio/gateway      	1.25.0       	1.25.0     	Helm chart for deploying Istio gateways           
istio/ztunnel      	1.25.0       	1.25.0     	Helm chart for istio ztunnel components

# helm pull istio/base

# ls -la
total 80
drwxr-xr-x  2 root root  4096 Mar 17 13:46 .
drwx------ 10 root root  4096 Mar 17 13:29 ..
-rw-r--r--  1 root root 70022 Mar 17 13:46 base-1.25.0.tgz

# unp base-1.25.0.tgz 
base/Chart.yaml
base/values.yaml
base/templates/NOTES.txt
base/templates/crds.yaml
base/templates/defaultrevision-validatingadmissionpolicy.yaml
base/templates/defaultrevision-validatingwebhookconfiguration.yaml
base/templates/reader-serviceaccount.yaml
base/templates/zzz_profile.yaml
base/README.md
base/files/crd-all.gen.yaml
base/files/profile-ambient.yaml
base/files/profile-compatibility-version-1.22.yaml
base/files/profile-compatibility-version-1.23.yaml
base/files/profile-compatibility-version-1.24.yaml
base/files/profile-demo.yaml
base/files/profile-platform-gke.yaml
base/files/profile-platform-k3d.yaml
base/files/profile-platform-k3s.yaml
base/files/profile-platform-microk8s.yaml
base/files/profile-platform-minikube.yaml
base/files/profile-platform-openshift.yaml
base/files/profile-preview.yaml
base/files/profile-remote.yaml
base/files/profile-stable.yaml

# cat base/values.yaml 
```


Can also get istio chart versions from:
- https://github.com/istio/istio/releases
- https://gcsweb.istio.io/gcs/istio-release/releases/1.25.0/helm/


Apply the created helmfile.yml
```
# export KUBECONFIG=/etc/kubernetes/admin.conf

# helmfile apply
Upgrading release=istio-base, chart=istio/base, namespace=istio-system
Upgrading release=istiod, chart=istio/istiod, namespace=istio-system
Release "istiod" does not exist. Installing it now.
NAME: istiod
LAST DEPLOYED: Mon Mar 17 13:53:30 2025
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
"istiod" successfully installed!

To learn more about the release, try:
  $ helm status istiod -n istio-system
  $ helm get all istiod -n istio-system

Next steps:
  * Deploy a Gateway: https://istio.io/latest/docs/setup/additional-setup/gateway/
  * Try out our tasks to get started on common configurations:
    * https://istio.io/latest/docs/tasks/traffic-management
    * https://istio.io/latest/docs/tasks/security/
    * https://istio.io/latest/docs/tasks/policy-enforcement/
  * Review the list of actively supported releases, CVE publications and our hardening guide:
    * https://istio.io/latest/docs/releases/supported-releases/
    * https://istio.io/latest/news/security/
    * https://istio.io/latest/docs/ops/best-practices/security/

For further documentation see https://istio.io website

Listing releases matching ^istiod$
istiod	istio-system	1       	2025-03-17 13:53:30.078896236 +0000 UTC	deployed	istiod-1.25.0	1.25.0     

Release "istio-base" does not exist. Installing it now.
NAME: istio-base
LAST DEPLOYED: Mon Mar 17 13:53:29 2025
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Istio base successfully installed!

To learn more about the release, try:
  $ helm status istio-base -n istio-system
  $ helm get all istio-base -n istio-system

Listing releases matching ^istio-base$
istio-base	istio-system	1       	2025-03-17 13:53:29.82126773 +0000 UTC	deployed	base-1.25.0	1.25.0     


UPDATED RELEASES:
NAME         NAMESPACE      CHART          VERSION   DURATION
istiod       istio-system   istio/istiod   1.25.0          2s
istio-base   istio-system   istio/base     1.25.0          3s
```


Verify pod is running:
```
# k get pods -A -o wide
NAMESPACE      NAME                             READY   STATUS    RESTARTS         AGE     IP             NODE      NOMINATED NODE   READINESS GATES
home           http-server-56bb7f7b5b-6hnnf     1/1     Running   9 (91m ago)      3d22h   10.244.1.108   worker1   <none>           <none>
home           http-server-56bb7f7b5b-b4rm5     1/1     Running   9 (91m ago)      3d22h   10.244.1.106   worker1   <none>           <none>
home           http-server-56bb7f7b5b-f2btm     1/1     Running   9 (91m ago)      3d22h   10.244.1.107   worker1   <none>           <none>
home           http-server-56bb7f7b5b-rbvk2     1/1     Running   12 (91m ago)     16d     10.244.1.105   worker1   <none>           <none>
istio-system   istiod-558554f5df-56pfh          1/1     Running   0                2m58s   10.244.3.2     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh            1/1     Running   3 (90m ago)      19h     10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4            1/1     Running   16 (88m ago)     20h     10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7            1/1     Running   4 (89m ago)      18h     10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk            1/1     Running   4 (89m ago)      19h     10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw         1/1     Running   2 (91m ago)      19h     10.244.2.4     worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   14 (91m ago)     19d     10.244.0.27    master    <none>           <none>
kube-system    etcd-master                      1/1     Running   20 (3h18m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master            1/1     Running   20 (3h18m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master   1/1     Running   21 (3h18m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                 1/1     Running   7 (91m ago)      3d14h   10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                 1/1     Running   6 (3h18m ago)    3d14h   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                 1/1     Running   3 (91m ago)      20h     10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                 1/1     Running   4 (91m ago)      20h     10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master            1/1     Running   16 (3h18m ago)   19d     10.128.0.16    master    <none>           <none>
```



# Install kiali and prometheus

Edit helmfile to add the two charts.

see:
- https://istio.io/latest/docs/ops/integrations/kiali/
- https://istio.io/latest/docs/ops/integrations/prometheus/


