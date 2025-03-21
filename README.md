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


### Install kiali

For kiali-operator its possible to create custom-resource directly in the helm values.yaml, however helmfile does not like that.
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


### Uninstalling

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
```

After removing PV, if using static storage provisioning, remember to find the folder and clear its contents:
```
$  yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1
# cd /opt/my-local-storage/worker1-pv1/
# rm -rf ./*
```
