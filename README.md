# Service account with kube-api-server /metrics endpoint access

### About metrics api

Metrics pipeline overview: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

Metrics server implementation to provide `metrics.k8s.io` api: https://github.com/kubernetes-sigs/metrics-server

Metrics format exposed by metrics-server: https://kubernetes.io/docs/reference/instrumentation/metrics/

See also: https://kubernetes.io/docs/reference/external-api/metrics.v1beta1/


Check if any metrics api is already installed (e.g. metrics.k8s.io):
```
$ k api-resources -o wide
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
secrets                                          v1                                true         Secret                             create,delete,deletecollection,get,list,patch,update,watch   
serviceaccounts                     sa           v1                                true         ServiceAccount                     create,delete,deletecollection,get,list,patch,update,watch   
services                            svc          v1                                true         Service                            create,delete,deletecollection,get,list,patch,update,watch   all
mutatingwebhookconfigurations                    admissionregistration.k8s.io/v1   false        MutatingWebhookConfiguration       create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingadmissionpolicies                      admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicy          create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingadmissionpolicybindings                admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicyBinding   create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingwebhookconfigurations                  admissionregistration.k8s.io/v1   false        ValidatingWebhookConfiguration     create,delete,deletecollection,get,list,patch,update,watch   api-extensions
customresourcedefinitions           crd,crds     apiextensions.k8s.io/v1           false        CustomResourceDefinition           create,delete,deletecollection,get,list,patch,update,watch   api-extensions
apiservices                                      apiregistration.k8s.io/v1         false        APIService                         create,delete,deletecollection,get,list,patch,update,watch   api-extensions
controllerrevisions                              apps/v1                           true         ControllerRevision                 create,delete,deletecollection,get,list,patch,update,watch   
daemonsets                          ds           apps/v1                           true         DaemonSet                          create,delete,deletecollection,get,list,patch,update,watch   all
deployments                         deploy       apps/v1                           true         Deployment                         create,delete,deletecollection,get,list,patch,update,watch   all
replicasets                         rs           apps/v1                           true         ReplicaSet                         create,delete,deletecollection,get,list,patch,update,watch   all
statefulsets                        sts          apps/v1                           true         StatefulSet                        create,delete,deletecollection,get,list,patch,update,watch   all
selfsubjectreviews                               authentication.k8s.io/v1          false        SelfSubjectReview                  create                                                       
tokenreviews                                     authentication.k8s.io/v1          false        TokenReview                        create                                                       
localsubjectaccessreviews                        authorization.k8s.io/v1           true         LocalSubjectAccessReview           create                                                       
selfsubjectaccessreviews                         authorization.k8s.io/v1           false        SelfSubjectAccessReview            create                                                       
selfsubjectrulesreviews                          authorization.k8s.io/v1           false        SelfSubjectRulesReview             create                                                       
subjectaccessreviews                             authorization.k8s.io/v1           false        SubjectAccessReview                create                                                       
horizontalpodautoscalers            hpa          autoscaling/v2                    true         HorizontalPodAutoscaler            create,delete,deletecollection,get,list,patch,update,watch   all
cronjobs                            cj           batch/v1                          true         CronJob                            create,delete,deletecollection,get,list,patch,update,watch   all
jobs                                             batch/v1                          true         Job                                create,delete,deletecollection,get,list,patch,update,watch   all
certificatesigningrequests          csr          certificates.k8s.io/v1            false        CertificateSigningRequest          create,delete,deletecollection,get,list,patch,update,watch   
leases                                           coordination.k8s.io/v1            true         Lease                              create,delete,deletecollection,get,list,patch,update,watch   
endpointslices                                   discovery.k8s.io/v1               true         EndpointSlice                      create,delete,deletecollection,get,list,patch,update,watch   
events                              ev           events.k8s.io/v1                  true         Event                              create,delete,deletecollection,get,list,patch,update,watch   
wasmplugins                                      extensions.istio.io/v1alpha1      true         WasmPlugin                         delete,deletecollection,get,list,patch,create,update,watch   istio-io,extensions-istio-io
flowschemas                                      flowcontrol.apiserver.k8s.io/v1   false        FlowSchema                         create,delete,deletecollection,get,list,patch,update,watch   
prioritylevelconfigurations                      flowcontrol.apiserver.k8s.io/v1   false        PriorityLevelConfiguration         create,delete,deletecollection,get,list,patch,update,watch   
kialis                                           kiali.io/v1alpha1                 true         Kiali                              delete,deletecollection,get,list,patch,create,update,watch   
destinationrules                    dr           networking.istio.io/v1            true         DestinationRule                    delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
envoyfilters                                     networking.istio.io/v1alpha3      true         EnvoyFilter                        delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
gateways                            gw           networking.istio.io/v1            true         Gateway                            delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
proxyconfigs                                     networking.istio.io/v1beta1       true         ProxyConfig                        delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
serviceentries                      se           networking.istio.io/v1            true         ServiceEntry                       delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
sidecars                                         networking.istio.io/v1            true         Sidecar                            delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
virtualservices                     vs           networking.istio.io/v1            true         VirtualService                     delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
workloadentries                     we           networking.istio.io/v1            true         WorkloadEntry                      delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
ingressclasses                                   networking.k8s.io/v1              false        IngressClass                       create,delete,deletecollection,get,list,patch,update,watch   
ingresses                           ing          networking.k8s.io/v1              true         Ingress                            create,delete,deletecollection,get,list,patch,update,watch   
networkpolicies                     netpol       networking.k8s.io/v1              true         NetworkPolicy                      create,delete,deletecollection,get,list,patch,update,watch   
runtimeclasses                                   node.k8s.io/v1                    false        RuntimeClass                       create,delete,deletecollection,get,list,patch,update,watch   
poddisruptionbudgets                pdb          policy/v1                         true         PodDisruptionBudget                create,delete,deletecollection,get,list,patch,update,watch   
clusterrolebindings                              rbac.authorization.k8s.io/v1      false        ClusterRoleBinding                 create,delete,deletecollection,get,list,patch,update,watch   
clusterroles                                     rbac.authorization.k8s.io/v1      false        ClusterRole                        create,delete,deletecollection,get,list,patch,update,watch   
rolebindings                                     rbac.authorization.k8s.io/v1      true         RoleBinding                        create,delete,deletecollection,get,list,patch,update,watch   
roles                                            rbac.authorization.k8s.io/v1      true         Role                               create,delete,deletecollection,get,list,patch,update,watch   
priorityclasses                     pc           scheduling.k8s.io/v1              false        PriorityClass                      create,delete,deletecollection,get,list,patch,update,watch   
authorizationpolicies               ap           security.istio.io/v1              true         AuthorizationPolicy                delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
peerauthentications                 pa           security.istio.io/v1              true         PeerAuthentication                 delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
requestauthentications              ra           security.istio.io/v1              true         RequestAuthentication              delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
csidrivers                                       storage.k8s.io/v1                 false        CSIDriver                          create,delete,deletecollection,get,list,patch,update,watch   
csinodes                                         storage.k8s.io/v1                 false        CSINode                            create,delete,deletecollection,get,list,patch,update,watch   
csistoragecapacities                             storage.k8s.io/v1                 true         CSIStorageCapacity                 create,delete,deletecollection,get,list,patch,update,watch   
storageclasses                      sc           storage.k8s.io/v1                 false        StorageClass                       create,delete,deletecollection,get,list,patch,update,watch   
volumeattachments                                storage.k8s.io/v1                 false        VolumeAttachment                   create,delete,deletecollection,get,list,patch,update,watch   
telemetries                         telemetry    telemetry.istio.io/v1             true         Telemetry                          delete,deletecollection,get,list,patch,create,update,watch   istio-io,telemetry-istio-io
```

There are kiali and istio resources, but unfortunatelly no metrics api resource.

Verify that kubectl top fails:
```
$ k get pods -n default
NAME                           READY   STATUS    RESTARTS   AGE
http-server-5c4c6474b5-2jf8g   1/1     Running   0          34m

$ k top pod http-server-5c4c6474b5-2jf8g
error: Metrics API not available

$ k top node worker1
error: Metrics API not available
```



### Install metrics-server:

Separate cAdvisor install is not necessary. By default, Kubernetes fetches node summary metrics data using an embedded cAdvisor
that runs within the kubelet. see: https://kubernetes.io/docs/reference/instrumentation/node-metrics/#summary-api-source

Also some container runtimes supports statistics access via Container Runtime Interface (CRI), see: https://kubernetes.io/docs/reference/instrumentation/cri-pod-container-metrics/


Helm install, see: https://github.com/kubernetes-sigs/metrics-server:
```
# helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
"metrics-server" has been added to your repositories

# helm upgrade --install metrics-server metrics-server/metrics-server
Release "metrics-server" does not exist. Installing it now.
NAME: metrics-server
LAST DEPLOYED: Sun Mar 23 06:41:50 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
***********************************************************************
* Metrics Server                                                      *
***********************************************************************
  Chart version: 3.12.2
  App version:   0.7.2
  Image tag:     registry.k8s.io/metrics-server/metrics-server:v0.7.2
***********************************************************************

# k get pods -A
NAMESPACE      NAME                              READY   STATUS    RESTARTS       AGE
default        http-server-5c4c6474b5-2jf8g      1/1     Running   0              63m
default        metrics-server-6fdb59879c-lgpl5   0/1     Running   0              29s
kube-flannel   kube-flannel-ds-hjwfh             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-q2gl4             1/1     Running   20 (12h ago)   6d12h
kube-flannel   kube-flannel-ds-sq6s7             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-sx6qk             1/1     Running   6 (12h ago)    6d11h
kube-system    coredns-7c65d6cfc9-gmzxw          1/1     Running   4 (12h ago)    6d11h
kube-system    coredns-7c65d6cfc9-pk4xt          1/1     Running   16 (12h ago)   25d
kube-system    etcd-master                       1/1     Running   22 (12h ago)   55d
kube-system    kube-apiserver-master             1/1     Running   22 (12h ago)   55d
kube-system    kube-controller-manager-master    1/1     Running   23 (12h ago)   55d
kube-system    kube-proxy-bp57z                  1/1     Running   9 (12h ago)    9d
kube-system    kube-proxy-hkklk                  1/1     Running   8 (12h ago)    9d
kube-system    kube-proxy-x4qcl                  1/1     Running   5 (23h ago)    6d12h
kube-system    kube-proxy-z5ztj                  1/1     Running   6 (12h ago)    6d12h
kube-system    kube-scheduler-master             1/1     Running   18 (12h ago)   25d

k logs metrics-server-6fdb59879c-lgpl5
I0323 06:43:01.775649       1 server.go:191] "Failed probe" probe="metric-storage-ready" err="no metrics to serve"
I0323 06:43:11.775612       1 server.go:191] "Failed probe" probe="metric-storage-ready" err="no metrics to serve"
E0323 06:43:14.880361       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.3:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.3 because it doesn't contain any IP SANs" node="worker3"
E0323 06:43:14.883126       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.16:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.16 because it doesn't contain any IP SANs" node="master"
E0323 06:43:14.889181       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.26:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.26 because it doesn't contain any IP SANs" node="worker2"
E0323 06:43:14.904774       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.25:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.25 because it doesn't contain any IP SANs" node="worker1"
```

Problems with startup of metrics-server. Disable tls verification and re-install, see https://github.com/kubernetes-sigs/metrics-server?tab=readme-ov-file#configuration:
```
$ helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
"metrics-server" has been added to your repositories

$ helm search repo metrics-server
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/metrics-server       	7.4.1        	0.7.2      	Metrics Server aggregates resource usage data, ...
metrics-server/metrics-server	3.12.2       	0.7.2      	Metrics Server is a scalable, efficient source ...

$ helm pull metrics-server/metrics-server

$ unp metrics-server-3.12.2.tgz 
metrics-server/Chart.yaml
metrics-server/values.yaml
metrics-server/templates/NOTES.txt
metrics-server/templates/_helpers.tpl
metrics-server/templates/apiservice.yaml
metrics-server/templates/clusterrole-aggregated-reader.yaml
metrics-server/templates/clusterrole-nanny.yaml
metrics-server/templates/clusterrole.yaml
metrics-server/templates/clusterrolebinding-auth-delegator.yaml
metrics-server/templates/clusterrolebinding-nanny.yaml
metrics-server/templates/clusterrolebinding.yaml
metrics-server/templates/configmaps-nanny.yaml
metrics-server/templates/deployment.yaml
metrics-server/templates/pdb.yaml
metrics-server/templates/psp.yaml
metrics-server/templates/role-nanny.yaml
metrics-server/templates/rolebinding-nanny.yaml
metrics-server/templates/rolebinding.yaml
metrics-server/templates/service.yaml
metrics-server/templates/serviceaccount.yaml
metrics-server/templates/servicemonitor.yaml
metrics-server/.helmignore
metrics-server/CHANGELOG.md
metrics-server/README.md
metrics-server/RELEASE.md
metrics-server/ci/ci-values.yaml

$ less metrics-server/values.yaml
```

Clean re-install:
```
$ helm upgrade --install metrics-server metrics-server/metrics-server -f values-metrics-server.yaml 
Release "metrics-server" has been upgraded. Happy Helming!
NAME: metrics-server
LAST DEPLOYED: Sun Mar 23 11:59:19 2025
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
***********************************************************************
* Metrics Server                                                      *
***********************************************************************
  Chart version: 3.12.2
  App version:   0.7.2
  Image tag:     registry.k8s.io/metrics-server/metrics-server:v0.7.2
***********************************************************************

$ k get pods -A
NAMESPACE      NAME                              READY   STATUS    RESTARTS       AGE
default        http-server-5c4c6474b5-2jf8g      1/1     Running   0              81m
default        metrics-server-6f665c9d54-nrj7b   1/1     Running   0              66s
kube-flannel   kube-flannel-ds-hjwfh             1/1     Running   7 (12h ago)    6d12h
kube-flannel   kube-flannel-ds-q2gl4             1/1     Running   20 (12h ago)   6d13h
kube-flannel   kube-flannel-ds-sq6s7             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-sx6qk             1/1     Running   6 (12h ago)    6d12h
kube-system    coredns-7c65d6cfc9-gmzxw          1/1     Running   4 (12h ago)    6d12h
kube-system    coredns-7c65d6cfc9-pk4xt          1/1     Running   16 (12h ago)   25d
kube-system    etcd-master                       1/1     Running   22 (12h ago)   55d
kube-system    kube-apiserver-master             1/1     Running   22 (12h ago)   55d
kube-system    kube-controller-manager-master    1/1     Running   23 (12h ago)   55d
kube-system    kube-proxy-bp57z                  1/1     Running   9 (12h ago)    9d
kube-system    kube-proxy-hkklk                  1/1     Running   8 (12h ago)    9d
kube-system    kube-proxy-x4qcl                  1/1     Running   5 (23h ago)    6d13h
kube-system    kube-proxy-z5ztj                  1/1     Running   6 (12h ago)    6d13h
kube-system    kube-scheduler-master             1/1     Running   18 (12h ago)   25d

$ k get svc -A
NAMESPACE     NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default       http-server      ClusterIP   10.255.8.210     <none>        8080/TCP                 11h
default       kubernetes       ClusterIP   10.255.0.1       <none>        443/TCP                  55d
default       metrics-server   ClusterIP   10.255.193.237   <none>        443/TCP                  20m
kube-system   kube-dns         ClusterIP   10.255.0.10      <none>        53/UDP,53/TCP,9153/TCP   55d
```


Verify kubectl top works:
```
$ k top node worker1
NAME      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
worker1   19m          0%       585Mi           7%
```

### Try /metrics access from pod using "default" Service Account

Create deployment:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created
```

Try to access /metrics with curl from debug container:
```
$ k debug -it --profile=sysadmin --image=nicolaka/netshoot:v0.13 -n default --target=server-container http-server-5c4c6474b5-2jf8g
                                         
http-server-5c4c6474b5-2jf8g  ~  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
cat: can't open '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory

http-server-5c4c6474b5-2jf8g  ~  ps   
PID   USER     TIME  COMMAND
    1 root      0:00 python -m http.server 8080 --directory /opt
    7 root      0:01 zsh
   93 root      0:00 ps
http-server-5c4c6474b5-2jf8g  ~  ls -la /proc/1/root/var/run/  
total 8
drwxr-xr-x    2 root     root          4096 Jan 26  2024 .
drwxr-xr-x    1 root     root          4096 Mar 23 05:43 ..

http-server-5c4c6474b5-2jf8g  ~  ls -la /var/run
total 8
drwxr-xr-x    2 root     root          4096 Jan 26  2024 .
drwxr-xr-x    1 root     root          4096 Mar 23 05:47 ..
```

However the debug container does not get kube token secret installed and looks like it can not access pod's secret token either.

Try to exec into pod:
```
$ k exec -it http-server-5c4c6474b5-2jf8g -- /bin/bash

root@http-server-5c4c6474b5-2jf8g:~# find /var/run/
/var/run/
/var/run/lock
/var/run/secrets
/var/run/secrets/kubernetes.io
/var/run/secrets/kubernetes.io/serviceaccount
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/token
/var/run/secrets/kubernetes.io/serviceaccount/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..data
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/token
/var/run/adduser

```


# create service account

```
$ k apply -f sa-monitoring.yaml 
serviceaccount/monitoring created
```
