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
```

