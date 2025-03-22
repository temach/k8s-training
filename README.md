# k8s-training

# Install istio, kiali, prometheus

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


### Install kiali

See: https://istio.io/latest/docs/ops/integrations/kiali/

For kiali-operator its possible to create custom-resource directly in the helm values.yaml, but first time do things by hand.
So first comment the installation of "cr:" in helmfile for kiali, install it, then uncomment and install again.

Error shown below:
```
# helmfile apply
...
Comparing release=kiali-operator, chart=kiali/kiali-operator, namespace=kiali
in ./helmfile.yaml: command "/usr/local/bin/helm" exited with non-zero status:

PATH:
  /usr/local/bin/helm

ARGS:
  0: helm (4 bytes)
  1: diff (4 bytes)
  2: upgrade (7 bytes)
  3: --allow-unreleased (18 bytes)
  4: kiali-operator (14 bytes)
  5: kiali/kiali-operator (20 bytes)
  6: --version (9 bytes)
  7: 2.7.0 (5 bytes)
  8: --namespace (11 bytes)
  9: kiali (5 bytes)
  10: --values (8 bytes)
  11: /tmp/helmfile431118674/kiali-kiali-operator-values-66f5d9d464 (61 bytes)
  12: --detailed-exitcode (19 bytes)
  13: --color (7 bytes)
  14: --reset-values (14 bytes)

ERROR:
  exit status 1

EXIT STATUS
  1

STDERR:
  Error: Failed to render chart: exit status 1: Error: unable to build kubernetes objects from release manifest: resource mapping not found for name: "kiali-server" namespace: "" from "": no matches for kind "Kiali" in version "kiali.io/v1alpha1"
  ensure CRDs are installed first
  Error: plugin "diff" exited with error

COMBINED OUTPUT:
  ********************
  	Release was not present in Helm.  Diff will show entire contents as new.
  ********************
  Error: Failed to render chart: exit status 1: Error: unable to build kubernetes objects from release manifest: resource mapping not found for name: "kiali-server" namespace: "" from "": no matches for kind "Kiali" in version "kiali.io/v1alpha1"
  ensure CRDs are installed first
  Error: plugin "diff" exited with error
```


Fix helmfile with a comment:
```
# vim helmfile.yaml
# cat helmfile.yaml
repositories:
  - name: istio
    url: https://istio-release.storage.googleapis.com/charts
  - name: prometheus-community
    url: https://prometheus-community.github.io/helm-charts
  - name: kiali
    url: https://kiali.org/helm-charts/

helmDefaults:
  # automatically create release namespaces if they do not exist
  createNamespace: true

releases:
  - name: istio-base
    namespace: istio-system
    chart: istio/base
    version: "1.25.0"

  - name: istiod
    namespace: istio-system
    chart: istio/istiod
    version: "1.25.0"

  - name: prometheus
    namespace: prometheus
    chart: prometheus-community/prometheus
    version: "27.5.1"

  - name: kiali-operator
    namespace: kiali
    chart: kiali/kiali-operator
    version: "2.7.0"
    # values:
    #   - cr:
    #       # For what a Kiali CR spec can look like, see: https://kiali.io/docs/configuration/kialis.kiali.io/
    #       create: true
    #       name: kiali-server
    #       spec:
    #         deployment:
    #           service_type: "ClusterIP"
```

Install again:
```
# helmfile apply
Upgrading release=prometheus, chart=prometheus-community/prometheus, namespace=prometheus
Upgrading release=kiali-operator, chart=kiali/kiali-operator, namespace=kiali
Release "kiali-operator" does not exist. Installing it now.
NAME: kiali-operator
LAST DEPLOYED: Mon Mar 17 14:19:43 2025
NAMESPACE: kiali
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Welcome to Kiali! For more details on Kiali, see: https://kiali.io

The Kiali Operator [v2.7.0] has been installed in namespace [kiali]. It will be ready soon.
You have elected not to install a Kiali CR. You must first install a Kiali CR before you can access Kiali. The operator is watching all namespaces, so you can create the Kiali CR anywhere.

If you ever want to uninstall the Kiali Operator, remember to delete the Kiali CR first before uninstalling the operator to give the operator a chance to uninstall and remove all the Kiali Server resources.

(Helm: Chart=[kiali-operator], Release=[kiali-operator], Version=[2.7.0])

Listing releases matching ^kiali-operator$
Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Mon Mar 17 14:19:42 2025
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.prometheus.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9090


The Prometheus alertmanager can be accessed via port 9093 on the following DNS name from within your cluster:
prometheus-alertmanager.prometheus.svc.cluster.local


Get the Alertmanager URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9093
#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
prometheus-prometheus-pushgateway.prometheus.svc.cluster.local


Get the PushGateway URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=prometheus-pushgateway,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9091

For more information on running Prometheus, visit:
https://prometheus.io/

Listing releases matching ^prometheus$
kiali-operator	kiali    	1       	2025-03-17 14:19:43.52301062 +0000 UTC	deployed	kiali-operator-2.7.0	v2.7.0

prometheus	prometheus	1       	2025-03-17 14:19:42.681917669 +0000 UTC	deployed	prometheus-27.5.1	v3.2.1


UPDATED RELEASES:
NAME             NAMESPACE    CHART                             VERSION   DURATION
kiali-operator   kiali        kiali/kiali-operator              2.7.0           3s
prometheus       prometheus   prometheus-community/prometheus   27.5.1          3s

```


Uncomment and install again, now kiali-server CustomResource should get applied and the kiali server will be installed:
```
# vim helmfile.yaml
# helmfile apply
...
Upgrading release=kiali-operator, chart=kiali/kiali-operator, namespace=kiali
Release "kiali-operator" has been upgraded. Happy Helming!
NAME: kiali-operator
LAST DEPLOYED: Mon Mar 17 14:22:12 2025
NAMESPACE: kiali
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
Welcome to Kiali! For more details on Kiali, see: https://kiali.io

The Kiali Operator [v2.7.0] has been installed in namespace [kiali]. It will be ready soon.
You have elected to install a Kiali CR in the same namespace as the operator [kiali]. You should be able to access Kiali soon.

================================
PLEASE READ THIS WARNING NOTICE:
Because the Kiali CR lives in the same namespace as the operator, DO NOT uninstall the operator or delete the operator namespace without first removing the Kiali CR. If you do not follow this advice then the Kiali Operator deletion will hang indefinitely until you remove the finalizer from the Kiali CR, and then you may find your Kubernetes environment still has Kiali Server remnants left behind.
================================

If you ever want to uninstall the Kiali Operator, remember to delete the Kiali CR first before uninstalling the operator to give the operator a chance to uninstall and remove all the Kiali Server resources.

(Helm: Chart=[kiali-operator], Release=[kiali-operator], Version=[2.7.0])

Listing releases matching ^kiali-operator$
kiali-operator	kiali    	2       	2025-03-17 14:22:12.692527255 +0000 UTC	deployed	kiali-operator-2.7.0	v2.7.0


UPDATED RELEASES:
NAME             NAMESPACE   CHART                  VERSION   DURATION
kiali-operator   kiali       kiali/kiali-operator   2.7.0           1s
```

Fix the helmfile for the future, by disabling CRD validation for kiali release:
```
    disableValidationOnInstall: false
```

### Install prometheus

See: https://istio.io/latest/docs/ops/integrations/prometheus/

At this point prometheus and alertmanager do not start, due to persistent volume requirements:
```
# k get pods -A -o wide
NAMESPACE      NAME                                                 READY   STATUS    RESTARTS         AGE     IP             NODE      NOMINATED NODE   READINESS GATES
home           http-server-56bb7f7b5b-6hnnf                         1/1     Running   9 (120m ago)     3d23h   10.244.1.108   worker1   <none>           <none>
home           http-server-56bb7f7b5b-b4rm5                         1/1     Running   9 (120m ago)     3d23h   10.244.1.106   worker1   <none>           <none>
home           http-server-56bb7f7b5b-f2btm                         1/1     Running   9 (120m ago)     3d23h   10.244.1.107   worker1   <none>           <none>
home           http-server-56bb7f7b5b-rbvk2                         1/1     Running   12 (120m ago)    16d     10.244.1.105   worker1   <none>           <none>
istio-system   istiod-558554f5df-56pfh                              1/1     Running   0                31m     10.244.3.2     worker3   <none>           <none>
kiali          kiali-7fb646f555-g2gfl                               1/1     Running   0                2m38s   10.244.2.8     worker2   <none>           <none>
kiali          kiali-operator-6bcdcb6998-fr562                      1/1     Running   0                5m25s   10.244.2.7     worker2   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh                                1/1     Running   3 (118m ago)     19h     10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4                                1/1     Running   16 (117m ago)    20h     10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7                                1/1     Running   4 (118m ago)     19h     10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk                                1/1     Running   4 (117m ago)     19h     10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw                             1/1     Running   2 (120m ago)     19h     10.244.2.4     worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt                             1/1     Running   14 (119m ago)    19d     10.244.0.27    master    <none>           <none>
kube-system    etcd-master                                          1/1     Running   20 (3h46m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master                                1/1     Running   20 (3h46m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master                       1/1     Running   21 (3h46m ago)   49d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                                     1/1     Running   7 (120m ago)     3d14h   10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                                     1/1     Running   6 (3h46m ago)    3d14h   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                                     1/1     Running   3 (120m ago)     20h     10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                                     1/1     Running   4 (120m ago)     20h     10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master                                1/1     Running   16 (3h46m ago)   19d     10.128.0.16    master    <none>           <none>
prometheus     prometheus-alertmanager-0                            0/1     Pending   0                5m25s   <none>         <none>    <none>           <none>
prometheus     prometheus-server-596945876b-qwn6n                   0/2     Pending   0                5m25s   <none>         <none>    <none>           <none>
prometheus     prometheus-kube-state-metrics-5bd466f7f6-h28v8       1/1     Running   0                5m25s   10.244.2.6     worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-k6ztj            1/1     Running   0                5m25s   10.128.0.25    worker1   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-rgm8b            1/1     Running   0                5m25s   10.128.0.3     worker3   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-w62hz            1/1     Running   0                5m25s   10.128.0.16    master    <none>           <none>
prometheus     prometheus-prometheus-node-exporter-zdn82            1/1     Running   0                5m25s   10.128.0.26    worker2   <none>           <none>
prometheus     prometheus-prometheus-pushgateway-544579d549-kgvmd   1/1     Running   0                5m25s   10.244.2.5     worker2   <none>           <none>
```

Update helmfile to turn off alertmanager and pushgateway and to fix PVC issue in prometheus, apply it:
```
# helmfile apply
...
Upgrading release=prometheus, chart=prometheus-community/prometheus, namespace=prometheus
Release "prometheus" has been upgraded. Happy Helming!
NAME: prometheus
LAST DEPLOYED: Mon Mar 17 15:01:23 2025
NAMESPACE: prometheus
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.prometheus.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9090


#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################

For more information on running Prometheus, visit:
https://prometheus.io/

Listing releases matching ^prometheus$
prometheus	prometheus	2       	2025-03-17 15:01:23.127247049 +0000 UTC	deployed	prometheus-27.5.1	v3.2.1


UPDATED RELEASES:
NAME         NAMESPACE    CHART                             VERSION   DURATION
prometheus   prometheus   prometheus-community/prometheus   27.5.1          3s

```


Since helm does not delete pvc (see: https://github.com/helm/helm/issues/5156#issuecomment-492560732 ), erase them by hand:
```
# k get pvc -A
NAMESPACE    NAME                                STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
prometheus   prometheus-server                   Pending                                      local-storage   <unset>                 44m
prometheus   storage-prometheus-alertmanager-0   Pending                                      local-storage   <unset>                 44m

# k -n prometheus delete pvc storage-prometheus-alertmanager-0
persistentvolumeclaim "storage-prometheus-alertmanager-0" deleted
```


Now apply storage config:
```
# k apply -f storage.yaml
storageclass.storage.k8s.io/local-storage configured
persistentvolume/worker1-pv1 unchanged

# k get pv -A
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                          STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE
worker1-pv1   8Gi        RWO            Retain           Bound    prometheus/prometheus-server   local-storage   <unset>                          2m29s

# k get pvc -A
NAMESPACE    NAME                STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
prometheus   prometheus-server   Bound    worker1-pv1   8Gi        RWO            local-storage   <unset>                 51m
```

Access prometheus:
```
export POD_NAME=$(kubectl get pods --namespace prometheus -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace prometheus port-forward $POD_NAME 9090
```


### Uninstal and clean re-install

If re-install is necessary it can be quite difficult to uninstall kiali, see:
- https://kiali.io/docs/installation/installation-guide/example-install/#uninstall-kiali-operator
- https://pre-v1-41.kiali.io/documentation/v1.24/installation-guide/#_known_problem_uninstall_hangs

Verify that all resources are gone:
```
# kubectl get apiservices -A -o wide
NAME                              SERVICE   AVAILABLE   AGE
v1.                               Local     True        54d
v1.admissionregistration.k8s.io   Local     True        54d
v1.apiextensions.k8s.io           Local     True        54d
v1.apps                           Local     True        54d
v1.authentication.k8s.io          Local     True        54d
v1.authorization.k8s.io           Local     True        54d
v1.autoscaling                    Local     True        54d
v1.batch                          Local     True        54d
v1.certificates.k8s.io            Local     True        54d
v1.coordination.k8s.io            Local     True        54d
v1.discovery.k8s.io               Local     True        54d
v1.events.k8s.io                  Local     True        54d
v1.flowcontrol.apiserver.k8s.io   Local     True        54d
v1.networking.k8s.io              Local     True        54d
v1.node.k8s.io                    Local     True        54d
v1.policy                         Local     True        54d
v1.rbac.authorization.k8s.io      Local     True        54d
v1.scheduling.k8s.io              Local     True        54d
v1.storage.k8s.io                 Local     True        54d

# kubectl api-resources -o wide
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND                               VERBS                                                        CATEGORIES
bindings                                         v1                                true         Binding                            create
componentstatuses                   cs           v1                                false        ComponentStatus                    get,list
configmaps                          cm           v1                                true         ConfigMap                          create,delete,deletecollection,get,list,patch,update,watch
endpoints                           ep           v1                                true         Endpoints                          create,delete,deletecollection,get,list,patch,update,watch
events                              ev           v1                                true         Event                              create,delete,deletecollection,get,list,patch,update,watch
limitranges                         limits       v1                                true         LimitRange                         create,delete,deletecollection,get,list,patch,update,watch
namespaces                          ns           v1                                false        Namespace                          create,delete,get,list,patch,update,watch
nodes                               no           v1                                false        Node                               create,delete,deletecollection,get,list,patch,update,watch
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim              create,delete,deletecollection,get,list,patch,update,watch
persistentvolumes                   pv           v1                                false        PersistentVolume                   create,delete,deletecollection,get,list,patch,update,watch
pods                                po           v1                                true         Pod                                create,delete,deletecollection,get,list,patch,update,watch   all
podtemplates                                     v1                                true         PodTemplate                        create,delete,deletecollection,get,list,patch,update,watch
replicationcontrollers              rc           v1                                true         ReplicationController              create,delete,deletecollection,get,list,patch,update,watch   all
resourcequotas                      quota        v1                                true         ResourceQuota                      create,delete,deletecollection,get,list,patch,update,watch
```

Check the resources per each namespace:
```
# kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl -v=6 get --show-kind --ignore-not-found -n istio-system
# kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl -v=6 get --show-kind --ignore-not-found -n prometheus
# kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl -v=6 get --show-kind --ignore-not-found -n kiali
```

If necessary remove finalisers on crd:
```
# kubectl patch crd kialis.kiali.io -p '{"metadata":{"finalizers": []}}' --type=merge
```

Helm and helmfile remove pvc, but they do not remove PV (see: https://github.com/helm/helm/issues/5156 ):
```
# k get pv -o wide
# k delete pv worker1-pv1
```

However after deleting PV, it must be recreated, so new deployments can use it.
```
# kubectl apply -f storage.yaml
```

Alternative is to unbind PV manually by deleting claimRef and possibly finalisers, then PV itself is freed and can be re-used:
```
# kubectl patch pv worker1-pv1 -p '{"spec":{"claimRef": []}}' --type=merge
# kubectl patch pv worker1-pv1 -p '{"metadata":{"finalizers": []}}' --type=merge
```


After removing PV, if using static storage provisioning, remember to find the folder and clear its contents:
```
$  yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1
# cd /opt/my-local-storage/worker1-pv1/
# rm -rf ./*
```


# Clean re-install with one helmfile
```
# cd k8s-training/
# helmfile apply
...
Upgrading release=istio-base, chart=istio/base, namespace=istio-system
Upgrading release=prometheus, chart=prometheus-community/prometheus, namespace=prometheus
Upgrading release=istiod, chart=istio/istiod, namespace=istio-system
Upgrading release=kiali-operator, chart=kiali/kiali-operator, namespace=kiali
Release "istiod" does not exist. Installing it now.
NAME: istiod
LAST DEPLOYED: Fri Mar 21 13:12:00 2025
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
istiod	istio-system	1       	2025-03-21 13:12:00.636523782 +0000 UTC	deployed	istiod-1.25.0	1.25.0     

Release "istio-base" does not exist. Installing it now.
NAME: istio-base
LAST DEPLOYED: Fri Mar 21 13:12:00 2025
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
Release "kiali-operator" does not exist. Installing it now.
NAME: kiali-operator
LAST DEPLOYED: Fri Mar 21 13:12:02 2025
NAMESPACE: kiali
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Welcome to Kiali! For more details on Kiali, see: https://kiali.io

The Kiali Operator [v2.7.0] has been installed in namespace [kiali]. It will be ready soon.
You have elected to install a Kiali CR in the same namespace as the operator [kiali]. You should be able to access Kiali soon.

================================
PLEASE READ THIS WARNING NOTICE:
Because the Kiali CR lives in the same namespace as the operator, DO NOT uninstall the operator or delete the operator namespace without first removing the Kiali CR. If you do not follow this advice then the Kiali Operator deletion will hang indefinitely until you remove the finalizer from the Kiali CR, and then you may find your Kubernetes environment still has Kiali Server remnants left behind.
================================

If you ever want to uninstall the Kiali Operator, remember to delete the Kiali CR first before uninstalling the operator to give the operator a chance to uninstall and remove all the Kiali Server resources.

(Helm: Chart=[kiali-operator], Release=[kiali-operator], Version=[2.7.0])

Listing releases matching ^kiali-operator$
istio-base	istio-system	1       	2025-03-21 13:12:00.536986713 +0000 UTC	deployed	base-1.25.0	1.25.0     

kiali-operator	kiali    	1       	2025-03-21 13:12:02.516926011 +0000 UTC	deployed	kiali-operator-2.7.0	v2.7.0     

Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Fri Mar 21 13:12:02 2025
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.prometheus.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9090


#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################



For more information on running Prometheus, visit:
https://prometheus.io/

Listing releases matching ^prometheus$
prometheus	prometheus	1       	2025-03-21 13:12:02.168605986 +0000 UTC	deployed	prometheus-27.5.1	v3.2.1     


UPDATED RELEASES:
NAME             NAMESPACE      CHART                             VERSION   DURATION
istiod           istio-system   istio/istiod                      1.25.0          3s
istio-base       istio-system   istio/base                        1.25.0          5s
kiali-operator   kiali          kiali/kiali-operator              2.7.0           5s
prometheus       prometheus     prometheus-community/prometheus   27.5.1          6s
```

Check that kiali custom resource has been created, wait 10-15 minutes and then service + deployment should also get created:
```
$ k get kialis.kiali.io -A
NAMESPACE   NAME           AGE
kiali       kiali-server   157m

$ k get svc -A
NAMESPACE      NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
default        kubernetes                            ClusterIP   10.255.0.1       <none>        443/TCP                                 54d
home           http-server                           ClusterIP   10.255.36.158    <none>        8000/TCP                                28d
istio-system   istiod                                ClusterIP   10.255.78.29     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   173m
kiali          kiali                                 ClusterIP   10.255.231.137   <none>        20001/TCP,9090/TCP                      162m
kube-system    kube-dns                              ClusterIP   10.255.0.10      <none>        53/UDP,53/TCP,9153/TCP                  54d
prometheus     prometheus-kube-state-metrics         ClusterIP   10.255.244.83    <none>        8080/TCP                                173m
prometheus     prometheus-prometheus-node-exporter   ClusterIP   10.255.81.124    <none>        9100/TCP                                173m
prometheus     prometheus-server                     ClusterIP   10.255.20.134    <none>        80/TCP                                  173m

$ k get pods -A -o wide
NAMESPACE      NAME                                             READY   STATUS    RESTARTS         AGE     IP             NODE      NOMINATED NODE   READINESS GATES
home           http-server-56bb7f7b5b-6hnnf                     1/1     Running   10 (7h46m ago)   8d      10.244.1.114   worker1   <none>           <none>
home           http-server-56bb7f7b5b-b4rm5                     1/1     Running   10 (7h46m ago)   8d      10.244.1.115   worker1   <none>           <none>
home           http-server-56bb7f7b5b-f2btm                     1/1     Running   10 (7h46m ago)   8d      10.244.1.111   worker1   <none>           <none>
home           http-server-56bb7f7b5b-rbvk2                     1/1     Running   13 (7h46m ago)   21d     10.244.1.112   worker1   <none>           <none>
istio-system   istiod-558554f5df-hrd7f                          1/1     Running   0                176m    10.244.3.4     worker3   <none>           <none>
kiali          kiali-84cd7d5ccd-zzs8m                           1/1     Running   0                164m    10.244.2.15    worker2   <none>           <none>
kiali          kiali-operator-6bcdcb6998-wffm9                  1/1     Running   0                176m    10.244.2.13    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh                            1/1     Running   5 (7h44m ago)    4d21h   10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4                            1/1     Running   18 (7h44m ago)   4d22h   10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7                            1/1     Running   6 (7h44m ago)    4d21h   10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk                            1/1     Running   5 (7h46m ago)    4d21h   10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw                         1/1     Running   3 (7h46m ago)    4d21h   10.244.2.12    worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt                         1/1     Running   15 (7h46m ago)   23d     10.244.0.28    master    <none>           <none>
kube-system    etcd-master                                      1/1     Running   21 (7h46m ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master                            1/1     Running   21 (7h46m ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master                   1/1     Running   22 (7h46m ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                                 1/1     Running   8 (7h46m ago)    7d16h   10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                                 1/1     Running   7 (7h46m ago)    7d16h   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                                 1/1     Running   4 (7h46m ago)    4d22h   10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                                 1/1     Running   5 (7h46m ago)    4d22h   10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master                            1/1     Running   17 (7h46m ago)   23d     10.128.0.16    master    <none>           <none>
prometheus     prometheus-kube-state-metrics-5bd466f7f6-ngq95   1/1     Running   0                176m    10.244.2.14    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-97rmf        1/1     Running   0                176m    10.128.0.26    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-pkqmh        1/1     Running   0                176m    10.128.0.25    worker1   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-qlx2v        1/1     Running   0                176m    10.128.0.16    master    <none>           <none>
prometheus     prometheus-prometheus-node-exporter-x5jwx        1/1     Running   0                176m    10.128.0.3     worker3   <none>           <none>
prometheus     prometheus-server-88cb5cb78-ggqcp                2/2     Running   0                176m    10.244.1.116   worker1   <none>           <none>
```

# netshoot container to troubleshoot/debug if necessary

Overview of tools and a guide: https://hub.docker.com/r/nicolaka/netshoot

Kiali used wrong prometheus url by default (see: https://kiali.io/docs/configuration/kialis.kiali.io/#.spec.external_services.prometheus.url )
To diagnose use nicolaka/netshoot image.

Attach to kiali pod:
```
# k debug -it --profile=sysadmin --image=nicolaka/netshoot -n kiali --target=kiali pod/kiali-654966dc55-tmc8k
kiali-654966dc55-tmc8k  ~  ps auxf
PID   USER     TIME  COMMAND
    1 1000      0:01 /opt/kiali/kiali -config /kiali-configuration/config.yaml
   15 root      0:01 zsh
  222 root      0:00 ps auxf

kiali-654966dc55-tmc8k  ~  grep prometheus-server /proc/1/root/kiali-configuration/config.yaml
    url: http://prometheus-server.prometheus:80

Session ended, the ephemeral container will not be restarted but may be reattached using 'kubectl attach kiali-654966dc55-tmc8k -c debugger-j5jxx -i -t' if it is still running



# k describe -n kiali pod/kiali-654966dc55-tmc8k
...
Ephemeral Containers:
  debugger-j5jxx:
    Container ID:   docker://fe1077892acb9f516edbda09eb97badc8d239afe90790fa102f7c488ad8a10e7
    Image:          nicolaka/netshoot
    Image ID:       docker-pullable://nicolaka/netshoot@sha256:a20c2531bf35436ed3766cd6cfe89d352b050ccc4d7005ce6400adf97503da1b
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Error
      Exit Code:    130
      Started:      Sat, 22 Mar 2025 01:32:13 +0500
      Finished:     Sat, 22 Mar 2025 01:34:00 +0500
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:         <none>
...
```

Just run it in the same namespace (it does not auto-terminate):
```
# k run -it -n kiali netshoot1 --image=nicolaka/netshoot
$ curl http://prometheus-server.prometheus:80/
* Host prometheus-server.prometheus:80 was resolved.
* IPv6: (none)
* IPv4: 10.255.20.134
*   Trying 10.255.20.134:80...
* Connected to prometheus-server.prometheus (10.255.20.134) port 80
> GET / HTTP/1.1
> Host: prometheus-server.prometheus
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 302 Found
< Content-Type: text/html; charset=utf-8
< Location: /query
< Date: Fri, 21 Mar 2025 20:18:26 GMT
< Content-Length: 29
< 
<a href="/query">Found</a>.

Session ended, resume using 'kubectl attach netshoot1 -c netshoot1 -i -t' command when the pod is running
```


# Enjoy the service mesh

Forward port to UI from local machine:
```
$ k port-forward -n kiali svc/kiali 30000:20001
Forwarding from 127.0.0.1:30000 -> 20001
Forwarding from [::1]:30000 -> 20001
```

### Deploy app.yaml with service mesh

App to echo different HTTP statuses: https://github.com/aaronpowell/httpstatus
Which runs HTTP on port 8080 by default.

Namespace must have label:
```
kind: Namespace
metadata:
  labels:
    istio-injection: enabled
```

Adhere to istio special port naming convention with a dash "-" in Service objects.
see https://kiali.io/docs/features/validations/#kia0601---port-name-must-follow-protocol-suffix-form :
```
kind: Service
spec:
  ports:
    - name: http-main
```

And the app POD (not the deployment, the actual pod) needs to have labels:
```
kind: Deployment
spec:
  template:
    metadata:
      labels:
        app.kubernetes.io/name: http-server
        app.kubernetes.io/version: 0.6.9
```

Or the short version (but long version is more standard, see - https://helm.sh/docs/chart_best_practices/labels/#standard-labels ):
```
kind: Deployment
spec:
  template:
    metadata:
      labels:
        app: http-server
        version: 0.6.9
```

Deploy:
```
# k apply -f app.yaml 
namespace/home created
service/http-server created
deployment.apps/http-server created

# k get pods -A -o wide
NAMESPACE      NAME                                             READY   STATUS    RESTARTS       AGE     IP             NODE      NOMINATED NODE   READINESS GATES
home           http-server-857845bbb5-cstdc                     2/2     Running   0              70s     10.244.2.23    worker2   <none>           <none>
home           http-server-857845bbb5-hqsqt                     2/2     Running   0              70s     10.244.3.5     worker3   <none>           <none>
home           http-server-857845bbb5-txfq7                     2/2     Running   0              70s     10.244.1.117   worker1   <none>           <none>
home           http-server-857845bbb5-wgmq8                     2/2     Running   0              70s     10.244.1.118   worker1   <none>           <none>
istio-system   istiod-558554f5df-hrd7f                          1/1     Running   0              8h      10.244.3.4     worker3   <none>           <none>
kiali          kiali-654966dc55-tmc8k                           1/1     Running   0              51m     10.244.2.21    worker2   <none>           <none>
kiali          kiali-operator-6bcdcb6998-wffm9                  1/1     Running   0              8h      10.244.2.13    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh                            1/1     Running   5 (12h ago)    5d2h    10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4                            1/1     Running   18 (12h ago)   5d3h    10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7                            1/1     Running   6 (12h ago)    5d2h    10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk                            1/1     Running   5 (12h ago)    5d2h    10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw                         1/1     Running   3 (12h ago)    5d2h    10.244.2.12    worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt                         1/1     Running   15 (12h ago)   24d     10.244.0.28    master    <none>           <none>
kube-system    etcd-master                                      1/1     Running   21 (12h ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master                            1/1     Running   21 (12h ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master                   1/1     Running   22 (12h ago)   53d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                                 1/1     Running   8 (12h ago)    7d21h   10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                                 1/1     Running   7 (12h ago)    7d21h   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                                 1/1     Running   4 (12h ago)    5d3h    10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                                 1/1     Running   5 (12h ago)    5d3h    10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master                            1/1     Running   17 (12h ago)   24d     10.128.0.16    master    <none>           <none>
prometheus     prometheus-kube-state-metrics-5bd466f7f6-ngq95   1/1     Running   0              8h      10.244.2.14    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-97rmf        1/1     Running   0              8h      10.128.0.26    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-pkqmh        1/1     Running   0              8h      10.128.0.25    worker1   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-qlx2v        1/1     Running   0              8h      10.128.0.16    master    <none>           <none>
prometheus     prometheus-prometheus-node-exporter-x5jwx        1/1     Running   0              8h      10.128.0.3     worker3   <none>           <none>
prometheus     prometheus-server-88cb5cb78-ggqcp                2/2     Running   0              8h      10.244.1.116   worker1   <none>           <none>


# k describe pod -n home http-server-857845bbb5-cstdc
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  106s  default-scheduler  Successfully assigned home/http-server-857845bbb5-cstdc to worker2
  Normal  Pulling    105s  kubelet            Pulling image "docker.io/istio/proxyv2:1.25.0"
  Normal  Pulled     96s   kubelet            Successfully pulled image "docker.io/istio/proxyv2:1.25.0" in 9.098s (9.098s including waiting). Image size: 285485638 bytes.
  Normal  Created    77s   kubelet            Created container: istio-init
  Normal  Started    77s   kubelet            Started container istio-init
  Normal  Pulling    76s   kubelet            Pulling image "ghcr.io/aaronpowell/httpstatus:155dc50c6959df1db12cc0e07da3f2e0035a1426"
  Normal  Pulled     68s   kubelet            Successfully pulled image "ghcr.io/aaronpowell/httpstatus:155dc50c6959df1db12cc0e07da3f2e0035a1426" in 8.111s (8.111s including waiting). Image size: 226998178 bytes.
  Normal  Created    53s   kubelet            Created container: server-container
  Normal  Started    53s   kubelet            Started container server-container
  Normal  Pulled     53s   kubelet            Container image "docker.io/istio/proxyv2:1.25.0" already present on machine
  Normal  Created    53s   kubelet            Created container: istio-proxy
  Normal  Started    52s   kubelet            Started container istio-proxy
```

Make some requests to the service, they are successful!:
```
$ k port-forward -n home svc/http-server 8888:http-main
Forwarding from 127.0.0.1:8888 -> 8080
Forwarding from [::1]:8888 -> 8080

$ curl -v http://localhost:8888/200  
* Host localhost:8888 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8888...
* Connected to localhost (::1) port 8888
* using HTTP/1.x
> GET /200 HTTP/1.1
> Host: localhost:8888
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Content-Length: 6
< Content-Type: text/plain
< Date: Sat, 22 Mar 2025 03:54:46 GMT
< Server: Kestrel
< 
* Connection #0 to host localhost left intact
200 OK

$ curl -v http://localhost:8888/404
* Host localhost:8888 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8888...
* Connected to localhost (::1) port 8888
* using HTTP/1.x
> GET /404 HTTP/1.1
> Host: localhost:8888
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 404 Not Found
< Content-Length: 13
< Content-Type: text/plain
< Date: Sat, 22 Mar 2025 03:54:51 GMT
< Server: Kestrel
< 
* Connection #0 to host localhost left intact
404 Not Found
```

### Debug no traffic visible in kiali

Use debug on http-server pod to check istio rules:
```
$ k debug -it --profile=sysadmin --image=nicolaka/netshoot -n home --target=server-container http-server-b84f86b96-4lzpf

http-server-b84f86b96-4lzpf  ~  apk add iptables-legacy
fetch https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.19/community/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz
(1/3) Installing libip4tc (1.8.11-r1)
(2/3) Installing libip6tc (1.8.11-r1)
(3/3) Installing iptables-legacy (1.8.11-r1)
Executing busybox-1.36.1-r26.trigger
OK: 412 MiB in 275 packages

http-server-b84f86b96-4lzpf  ~  iptables-legacy-save   
# Generated by iptables-save v1.8.11 on Sat Mar 22 03:51:40 2025
*nat
:PREROUTING ACCEPT [1400:84000]
:INPUT ACCEPT [1400:84000]
:OUTPUT ACCEPT [154:13238]
:POSTROUTING ACCEPT [162:13718]
:ISTIO_INBOUND - [0:0]
:ISTIO_IN_REDIRECT - [0:0]
:ISTIO_OUTPUT - [0:0]
:ISTIO_REDIRECT - [0:0]
-A PREROUTING -p tcp -j ISTIO_INBOUND
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_INBOUND -p tcp -m tcp --dport 15008 -j RETURN
-A ISTIO_INBOUND -p tcp -m tcp --dport 15090 -j RETURN
-A ISTIO_INBOUND -p tcp -m tcp --dport 15021 -j RETURN
-A ISTIO_INBOUND -p tcp -m tcp --dport 15020 -j RETURN
-A ISTIO_INBOUND -p tcp -j ISTIO_IN_REDIRECT
-A ISTIO_IN_REDIRECT -p tcp -j REDIRECT --to-ports 15006
-A ISTIO_OUTPUT -s 127.0.0.6/32 -o lo -j RETURN
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -p tcp -m tcp ! --dport 15008 -m owner --uid-owner 1337 -j ISTIO_IN_REDIRECT
-A ISTIO_OUTPUT -o lo -m owner ! --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -p tcp -m tcp ! --dport 15008 -m owner --gid-owner 1337 -j ISTIO_IN_REDIRECT
-A ISTIO_OUTPUT -o lo -m owner ! --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
-A ISTIO_REDIRECT -p tcp -j REDIRECT --to-ports 15001
COMMIT
# Completed on Sat Mar 22 03:51:40 2025



$ k debug -it --profile=sysadmin --image=nicolaka/netshoot -n home --target=istio-proxy http-server-b84f86b96-4lzpf

http-server-b84f86b96-4lzpf  ~  ps auxf
PID   USER     TIME  COMMAND
    1 1337      0:03 /usr/local/bin/pilot-agent proxy sidecar --domain home.svc.cluster.local --proxyLogLevel=warning --proxyComponentLogLevel=misc:error --log_output_level=default:info
   14 1337      0:40 /usr/local/bin/envoy -c etc/istio/proxy/envoy-rev.json --drain-time-s 45 --drain-strategy immediate --local-address-ip-version v4 --file-flush-interval-msec 1000 --disable-hot-restart --allow-unknown-static-fields -l warning --component-log-level misc:error --skip-deprecated-logs --concurrency 2
   28 root      0:01 zsh
  163 root      0:00 ps auxf
  164 root      0:00 less

http-server-b84f86b96-4lzpf  ~  cat /proc/14/root/etc/istio/proxy/envoy-rev.json
{
  "application_log_config": {
    "log_format": {
        "text_format": "%Y-%m-%dT%T.%fZ\t%l\tenvoy %n %g:%#\t%v\tthread=%t"
    }
  },
  "node": {
    "id": "sidecar~10.244.1.122~http-server-b84f86b96-4lzpf.home~home.svc.cluster.local",
    "cluster": "http-server.home",
    "locality": {
      "region": "ru-central1"
      ,
      "zone": "ru-central1-a"
    },
    "metadata": {...},
  "layered_runtime": {
      "layers": [
          {
            "name": "global config",
            "static_layer": {"envoy.deprecated_features:envoy.config.listener.v3.Listener.hidden_envoy_deprecated_use_original_dst":true,"envoy.re
loadable_features.http_reject_path_with_fragment":false,"overload.global_downstream_max_connections":"2147483647","re2.max_program_size.error_leve
l":"32768"}
          },
          {
              "name": "admin",
              "admin_layer": {}
          }
      ]
  },
  "bootstrap_extensions": [
    {
      "name": "envoy.bootstrap.internal_listener",
      "typed_config": {
        "@type":"type.googleapis.com/udpa.type.v1.TypedStruct",
        "type_url": "type.googleapis.com/envoy.extensions.bootstrap.internal_listener.v3.InternalListener",
        "value": {
          "buffer_size_kb": 64
        }
      }
    }
  ],
  "stats_config": {
    "use_all_default_tags": false,
    "stats_tags": [
      {
        "tag_name": "cluster_name",
        "regex": "^cluster(\\.(.+);)"
      },
      {
        "tag_name": "http_conn_manager_prefix",
        "regex": "^http\\.(((?:[_.[:digit:]\\w]*|[_\\[\\]aAbBcCdDeEfF[:digit:]\\w\\:]*));\\.)"
      },
      {
        "tag_name": "thread_name",
        "regex": "^server(\\.(.+))\\.watchdog"
      },
      {
        "tag_name": "tcp_prefix",
        "regex": "^tcp\\.((.*?)\\.)\\w+?$"
      },
      {
        "regex": "_rq(_(\\d{3}))$",
        "tag_name": "response_code"
      },
      {
        "tag_name": "response_code_class",
        "regex": "_rq(_(\\dxx))$"
      },
      {
        "tag_name": "http_conn_manager_listener_prefix",
        "regex": "^listener(?=\\.).*?\\.http\\.(((?:[_.[:digit:]]*|[_\\[\\]aAbBcCdDeEfF[:digit:]]*))\\.)"
      },
      {
        "tag_name": "listener_address",
        "regex": "^listener\\.(((?:[_.[:digit:]]*|[_\\[\\]aAbBcCdDeEfF[:digit:]]*))\\.)"
      },
      {
        "tag_name": "mongo_prefix",
        "regex": "^mongo\\.(.+?)\\.(collection|cmd|cx_|op_|delays_|decoding_)(.*?)$"
      },
      {
        "regex": "(cache\\.(.+?)\\.)",
        "tag_name": "cache"
      },
      {
        "regex": "(component\\.(.+?)\\.)",
        "tag_name": "component"
      },
      {
        "regex": "(tag\\.(.+?);\\.)",
        "tag_name": "tag"
      },
      {
        "regex": "(wasm_filter\\.(.+?)\\.)",
        "tag_name": "wasm_filter"
      },
      {
        "tag_name": "authz_enforce_result",
        "regex": "rbac(\\.(allowed|denied))"
      },
      {
        "tag_name": "authz_dry_run_action",
        "regex": "(\\.istio_dry_run_(allow|deny)_)"
      },
      {
        "tag_name": "authz_dry_run_result",
        "regex": "(\\.shadow_(allowed|denied))"
      }
    ],
    "stats_matcher": {
      "inclusion_list": {
        "patterns": [
          {
          "prefix": "reporter="
          },
          {
          "prefix": "cluster_manager"
          },
          {
          "prefix": "listener_manager"
          },
          {
          "prefix": "server"
          },
          {
          "prefix": "cluster.xds-grpc"
          },
          {
          "prefix": "wasm"
          },
          {
          "suffix": "rbac.allowed"
          },
          {
          "suffix": "rbac.denied"
          },
          {
          "suffix": "shadow_allowed"
          },
          {
          "suffix": "shadow_denied"
          },
          {
          "safe_regex": {"regex":"vhost\\..*\\.route\\..*"}
          },
          {
          "prefix": "component"
          },
          {
          "prefix": "istio"
          }
        ]
      }
    }
  },
  "admin": {
    "access_log": [
      {
        "name": "envoy.access_loggers.file",
        "typed_config": {
          "@type": "type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog",
          "path": "/dev/null"
        }
      }
    ],
    "profile_path": "/var/lib/istio/data/envoy.prof",
    "address": {
      "socket_address": {
        "address": "127.0.0.1",
        "port_value": 15000
      }
    }
  },
  "dynamic_resources": {
    "lds_config": {
      "ads": {},
      "initial_fetch_timeout": "0s",
      "resource_api_version": "V3"
    },
    "cds_config": {
      "ads": {},
      "initial_fetch_timeout": "0s",
      "resource_api_version": "V3"
    },
    "ads_config": {
      "api_type": "DELTA_GRPC",
      "set_node_on_first_message_only": true,
      "transport_api_version": "V3",
      "grpc_services": [
        {
          "envoy_grpc": {
            "cluster_name": "xds-grpc"
          }
        }
      ]
    }
  },
  "static_resources": {
    "clusters": [
      {
        "name": "prometheus_stats",
        "alt_stat_name": "prometheus_stats;",
        "type": "STATIC",
        "connect_timeout": "0.250s",
        "lb_policy": "ROUND_ROBIN",
        "load_assignment": {
          "cluster_name": "prometheus_stats",
          "endpoints": [{
            "lb_endpoints": [{
              "endpoint": {
                "address":{
                  "socket_address": {
                    "protocol": "TCP",
                    "address": "127.0.0.1",
                    "port_value": 15000
                  }
                }
              }
            }]
          }]
        }
      },
      {
        "name": "agent",
        "alt_stat_name": "agent;",
        "type": "STATIC",
        "connect_timeout": "0.250s",
        "lb_policy": "ROUND_ROBIN",
        "load_assignment": {
          "cluster_name": "agent",
          "endpoints": [{
            "lb_endpoints": [{
              "endpoint": {
                "address":{
                  "socket_address": {
                    "protocol": "TCP",
                    "address": "127.0.0.1",
                    "port_value": 15020
                  }
                }
              }
            }]
          }]
        }
      },
      {
        "name": "sds-grpc",
        "alt_stat_name": "sds-grpc;",
        "type": "STATIC",
        "typed_extension_protocol_options": {
          "envoy.extensions.upstreams.http.v3.HttpProtocolOptions": {
           "@type": "type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions",
           "explicit_http_config": {
            "http2_protocol_options": {}
           }
          }
        },
        "connect_timeout": "1s",
        "lb_policy": "ROUND_ROBIN",
        "load_assignment": {
          "cluster_name": "sds-grpc",
          "endpoints": [{
            "lb_endpoints": [{
              "endpoint": {
                "address":{
                  "pipe": {
                    "path": "./var/run/secrets/workload-spiffe-uds/socket"
                  }
                }
              }
            }]
          }]
        }
      },
      {
        "name": "xds-grpc",
        "alt_stat_name": "xds-grpc;",
        "type" : "STATIC",
        "connect_timeout": "1s",
        "lb_policy": "ROUND_ROBIN",
        "load_assignment": {
          "cluster_name": "xds-grpc",
          "endpoints": [{
            "lb_endpoints": [{
              "endpoint": {
                "address":{
                  "pipe": {
                    "path": "./etc/istio/proxy/XDS"
                  }
                }
              }
            }]
          }]
        },
        "circuit_breakers": {
          "thresholds": [
            {
              "priority": "DEFAULT",
              "max_connections": 100000,
              "max_pending_requests": 100000,
              "max_requests": 100000
            },
            {
              "priority": "HIGH",
              "max_connections": 100000,
              "max_pending_requests": 100000,
              "max_requests": 100000
            }
          ]
        },
        "upstream_connection_options": {
          "tcp_keepalive": {
            "keepalive_time": 300
          }
        },
        "max_requests_per_connection": 1,
        "typed_extension_protocol_options": {
          "envoy.extensions.upstreams.http.v3.HttpProtocolOptions": {
           "@type": "type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions",
           "explicit_http_config": {
            "http2_protocol_options": {}
           }
          }
        }
      }
      
      
    ],
    "listeners":[
      {
        "name": "0.0.0.0_15090",
        
        "address": {
          "socket_address": {
            "protocol": "TCP",
            "address": "0.0.0.0",
            
            "port_value": 15090
          }
        },
        "ignore_global_conn_limit": true,
        "bypass_overload_manager": true,
        
        "filter_chains": [
          {
            "filters": [
              {
                "name": "envoy.filters.network.http_connection_manager",
                "typed_config": {
                  "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                  "codec_type": "AUTO",
                  "stat_prefix": "stats",
                  "route_config": {
                    "virtual_hosts": [
                      {
                        "name": "backend",
                        "domains": [
                          "*"
                        ],
                        "routes": [
                          {
                            "match": {
                              "prefix": "/stats/prometheus"
                            },
                            "route": {
                              "cluster": "prometheus_stats"
                            }
                          }
                        ]
                      }
                    ]
                  },
                  "http_filters": [
                  {
                    "name": "envoy.filters.http.router",
                    "typed_config": {
                      "@type": "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router"
                    }
                  }]
                }
              }
            ]
          }
        ]
      },
      {
        "name": "0.0.0.0_15021",
        "address": {
           "socket_address": {
             "protocol": "TCP",
             "address": "0.0.0.0",
             "port_value": 15021
           }
        },
        "ignore_global_conn_limit": true,
        "bypass_overload_manager": true,
        
        "filter_chains": [
          {
            "filters": [
              {
                "name": "envoy.filters.network.http_connection_manager",
                "typed_config": {
                  "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                  "codec_type": "AUTO",
                  "stat_prefix": "agent",
                  "route_config": {
                    "virtual_hosts": [
                      {
                        "name": "backend",
                        "domains": [
                          "*"
                        ],
                        "routes": [
                          {
                            "match": {
                              "prefix": "/healthz/ready"
                            },
                            "route": {
                              "cluster": "agent"
                            }
                          }
                        ]
                      }
                    ]
                  },
                  "http_filters": [{
                    "name": "envoy.filters.http.router",
                    "typed_config": {
                      "@type": "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router"
                    }
                  }]
                }
              }
            ]
          }
        ]
      }
    ]
  }
  ,
  "cluster_manager": {
    "enable_deferred_cluster_creation": true,
  }
  
  ,
  "deferred_stat_options": {
    "enable_deferred_creation_stats": true
  }
  
}

```


Generate some traffic `while true ; do curl http://158.160.61.136:30008/504 ; done` and check prometheus stats with debug container:
```
http-server-b84f86b96-4lzpf  ~  curl http://localhost:15090/stats/prometheus | grep -A30 istio_requests_total

# TYPE istio_requests_total counter
istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="404",grpc_response_status="",response_flags="-",connection_security_policy="none"} 815

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="spiffe://cluster.local/ns/home/sa/default",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="http-server",destination_workload_namespace="home",destination_principal="spiffe://cluster.local/ns/home/sa/default",destination_app="unknown",destination_version="unknown",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 1

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="unknown",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="prometheus-server",destination_workload_namespace="prometheus",destination_principal="unknown",destination_app="unknown",destination_version="unknown",destination_service="prometheus-server.prometheus.svc.cluster.local",destination_canonical_service="prometheus",destination_canonical_revision="v3.2.1",destination_service_name="prometheus-server",destination_service_namespace="prometheus",destination_cluster="Kubernetes",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 4

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="unknown",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="unknown",destination_workload_namespace="unknown",destination_principal="unknown",destination_app="unknown",destination_version="unknown",destination_service="dl-cdn.alpinelinux.org",destination_canonical_service="unknown",destination_canonical_revision="latest",destination_service_name="PassthroughCluster",destination_service_namespace="unknown",destination_cluster="unknown",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 12



http-server-b84f86b96-4lzpf  ~   curl http://localhost:15090/stats/prometheus | grep -A20 istio_requests_total           
# TYPE istio_requests_total counter
istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="none"} 12

istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="301",grpc_response_status="",response_flags="-",connection_security_policy="none"} 1

istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="404",grpc_response_status="",response_flags="-",connection_security_policy="none"} 2168

istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="500",grpc_response_status="",response_flags="-",connection_security_policy="none"} 1

istio_requests_total{reporter="destination",source_workload="unknown",source_canonical_service="unknown",source_canonical_revision="latest",source_workload_namespace="unknown",source_principal="unknown",source_app="unknown",source_version="unknown",source_cluster="unknown",destination_workload="http-server",destination_workload_namespace="home",destination_principal="unknown",destination_app="",destination_version="",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="504",grpc_response_status="",response_flags="-",connection_security_policy="none"} 39

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="spiffe://cluster.local/ns/home/sa/default",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="http-server",destination_workload_namespace="home",destination_principal="spiffe://cluster.local/ns/home/sa/default",destination_app="unknown",destination_version="unknown",destination_service="http-server.home.svc.cluster.local",destination_canonical_service="http-server",destination_canonical_revision="0.6.9",destination_service_name="http-server",destination_service_namespace="home",destination_cluster="Kubernetes",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 1

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="unknown",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="prometheus-server",destination_workload_namespace="prometheus",destination_principal="unknown",destination_app="unknown",destination_version="unknown",destination_service="prometheus-server.prometheus.svc.cluster.local",destination_canonical_service="prometheus",destination_canonical_revision="v3.2.1",destination_service_name="prometheus-server",destination_service_namespace="prometheus",destination_cluster="Kubernetes",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 4

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="unknown",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="prometheus-server",destination_workload_namespace="prometheus",destination_principal="unknown",destination_app="unknown",destination_version="unknown",destination_service="prometheus-server.prometheus.svc.cluster.local",destination_canonical_service="prometheus",destination_canonical_revision="v3.2.1",destination_service_name="prometheus-server",destination_service_namespace="prometheus",destination_cluster="Kubernetes",request_protocol="http",response_code="302",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 8

istio_requests_total{reporter="source",source_workload="http-server",source_canonical_service="http-server",source_canonical_revision="0.6.9",source_workload_namespace="home",source_principal="unknown",source_app="",source_version="",source_cluster="Kubernetes",destination_workload="unknown",destination_workload_namespace="unknown",destination_principal="unknown",destination_app="unknown",destination_version="unknown",destination_service="dl-cdn.alpinelinux.org",destination_canonical_service="unknown",destination_canonical_revision="latest",destination_service_name="PassthroughCluster",destination_service_namespace="unknown",destination_cluster="unknown",request_protocol="http",response_code="200",grpc_response_status="",response_flags="-",connection_security_policy="unknown"} 12
```

Note:
- 4 instances running and this are metrics from one instance only
- for some reason sending traffic via port-forward to svc/http-service did NOT change istio metrics, only traffic sent to NodePort appeared in istio metrics
- most traffic is 404 from internet bots (?)

Istio metrics are collected, and prometheus has istio-proxy as targets since istio by default has "prometheus.io" annotations and gets scraped.
see: https://istio.io/latest/docs/ops/integrations/prometheus/#option-1-metrics-merging

Checking the pods, this is indeed true (port 15020 and port 15090 both return metrics, not a problem):
```
$ k get pod -n home http-server-b84f86b96-4lzpf -o yaml | rg prometheus.io -C5
apiVersion: v1
kind: Pod
metadata:
  annotations:
    istio.io/rev: default
    kubectl.kubernetes.io/default-container: server-container
    kubectl.kubernetes.io/default-logs-container: server-container
    prometheus.io/path: /stats/prometheus
    prometheus.io/port: "15020"
    prometheus.io/scrape: "true"
  labels:
    app.kubernetes.io/name: http-server
```

Check that prometheus has these metrcis in prom UI:
```
$ k port-forward -n prometheus svc/prometheus-server 9090:80
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090

# Run query: sum(istio_requests_total{job="kubernetes-pods", namespace="home", pod="http-server-b84f86b96-4lzpf"}) by (response_code)
{response_code="200"}	29
{response_code="404"}	4449
{response_code="302"}	8
{response_code="500"}	1
{response_code="301"}	1
{response_code="504"}   39
```

### Fix kiali istio discovery

Accidentally found note that kiali expects to be installed into same namespace as istio, else it can break.
Added config option to discover istio namespace and re-created keali pod after which everything worked.
See: https://kiali.io/docs/installation/deployment-options/#kiali-and-istio-installation-namespaces

Service mesh screenshot:


