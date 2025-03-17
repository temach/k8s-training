# k8s-training

# Install istio

Reference lecture demo, see ./istio-k3d-demo.txt:
```
--------------------------
--- helm istio install ---
--------------------------

$ k3d cluster create mycluster

$ kubectl create ns istio-system

$ helm repo add istio https://istio-release.storage.googleapis.com/charts

$ helm repo update

$ helm install istio-base istio/base -n istio-system

$ helm install istiod istio/istiod -n istio-system --wait

$ helm list --namespace istio-system

$ kubectl get pod -n istio-system


-----------------------
--- manifests apply ---
-----------------------

$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/kiali.yaml

$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/prometheus.yaml

# change "type: ClusterIP" -> "type: NodePort"
$ kubectl edit svc kiali -n istio-system
```

