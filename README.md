# About /metrics api kube api server

Kubernetes has resource apis and non-resource-urls, this is visible in e.g:
```
$ k describe role -n kube-system kubeadm:nodes-kubeadm-config
Name:         kubeadm:nodes-kubeadm-config
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources   Non-Resource URLs  Resource Names    Verbs
  ---------   -----------------  --------------    -----
  configmaps  []                 [kubeadm-config]  [get]
```

Check /metrics raw api call works for admin:
```
$ k get --raw /metrics
# HELP aggregator_discovery_aggregation_count_total [ALPHA] Counter of number of times discovery was aggregated
# TYPE aggregator_discovery_aggregation_count_total counter
aggregator_discovery_aggregation_count_total 274
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
aggregator_unavailable_apiservice{name="v1."} 0
aggregator_unavailable_apiservice{name="v1.admissionregistration.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apiextensions.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apps"} 0
aggregator_unavailable_apiservice{name="v1.authentication.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.authorization.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.autoscaling"} 0
aggregator_unavailable_apiservice{name="v1.batch"} 0
aggregator_unavailable_apiservice{name="v1.certificates.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.coordination.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.discovery.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.events.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.flowcontrol.apiserver.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1.networking.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.node.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.policy"} 0
aggregator_unavailable_apiservice{name="v1.rbac.authorization.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.scheduling.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.security.istio.io"} 0
aggregator_unavailable_apiservice{name="v1.storage.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.telemetry.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.extensions.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.kiali.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.telemetry.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha3.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.metrics.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.security.istio.io"} 0
aggregator_unavailable_apiservice{name="v2.autoscaling"} 0
# HELP apiextensions_apiserver_validation_ratcheting_seconds [ALPHA] Time for comparison of old to new for the purposes of CRDValidationRatcheting during an UPDATE in seconds.
# TYPE apiextensions_apiserver_validation_ratcheting_seconds histogram
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="1e-05"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="4e-05"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.00016"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.00064"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.00256"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.01024"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.04096"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.16384"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="0.65536"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="2.62144"} 1
apiextensions_apiserver_validation_ratcheting_seconds_bucket{le="+Inf"} 1
apiextensions_apiserver_validation_ratcheting_seconds_sum 0
apiextensions_apiserver_validation_ratcheting_seconds_count 1
# HELP apiextensions_openapi_v2_regeneration_count [ALPHA] Counter of OpenAPI v2 spec regeneration count broken down by causing CRD name and reason.
# TYPE apiextensions_openapi_v2_regeneration_count counter
apiextensions_openapi_v2_regeneration_count{crd="authorizationpolicies.security.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="destinationrules.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="envoyfilters.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="gateways.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="kialis.kiali.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="peerauthentications.security.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="proxyconfigs.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="requestauthentications.security.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="serviceentries.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="sidecars.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="telemetries.telemetry.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="virtualservices.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="wasmplugins.extensions.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="workloadentries.networking.istio.io",reason="update"} 0
apiextensions_openapi_v2_regeneration_count{crd="workloadgroups.networking.istio.io",reason="remove"} 0
apiextensions_openapi_v2_regeneration_count{crd="workloadgroups.networking.istio.io",reason="update"} 0
# HELP apiextensions_openapi_v3_regeneration_count [ALPHA] Counter of OpenAPI v3 spec regeneration count broken down by group, version, causing CRD and reason.
# TYPE apiextensions_openapi_v3_regeneration_count counter
apiextensions_openapi_v3_regeneration_count{crd="authorizationpolicies.security.istio.io",group="security.istio.io",reason="add",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="authorizationpolicies.security.istio.io",group="security.istio.io",reason="add",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="destinationrules.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="destinationrules.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="destinationrules.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="envoyfilters.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="gateways.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="gateways.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="gateways.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="kialis.kiali.io",group="kiali.io",reason="add",version="v1alpha1"} 0
apiextensions_openapi_v3_regeneration_count{crd="peerauthentications.security.istio.io",group="security.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="peerauthentications.security.istio.io",group="security.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="proxyconfigs.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="requestauthentications.security.istio.io",group="security.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="requestauthentications.security.istio.io",group="security.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="serviceentries.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="serviceentries.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="serviceentries.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="sidecars.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="sidecars.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="sidecars.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="telemetries.telemetry.istio.io",group="telemetry.istio.io",reason="add",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="telemetries.telemetry.istio.io",group="telemetry.istio.io",reason="add",version="v1alpha1"} 0
apiextensions_openapi_v3_regeneration_count{crd="virtualservices.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="virtualservices.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="virtualservices.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="wasmplugins.extensions.istio.io",group="extensions.istio.io",reason="add",version="v1alpha1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadentries.networking.istio.io",group="networking.istio.io",reason="add",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadentries.networking.istio.io",group="networking.istio.io",reason="add",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadentries.networking.istio.io",group="networking.istio.io",reason="add",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="remove",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="remove",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="remove",version="v1beta1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="update",version="v1"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="update",version="v1alpha3"} 0
apiextensions_openapi_v3_regeneration_count{crd="workloadgroups.networking.istio.io",group="networking.istio.io",reason="update",version="v1beta1"} 0
# HELP apiserver_longrunning_requests [STABLE] Gauge of all active long-running apiserver requests broken out by verb, group, version, resource, scope and component. Not all requests are tracked this way.
# TYPE apiserver_longrunning_requests gauge
apiserver_longrunning_requests{component="apiserver",group="",resource="configmaps",scope="cluster",subresource="",verb="WATCH",version="v1"} 1
apiserver_longrunning_requests{component="apiserver",group="",resource="configmaps",scope="namespace",subresource="",verb="WATCH",version="v1"} 1
apiserver_longrunning_requests{component="apiserver",group="",resource="configmaps",scope="resource",subresource="",verb="WATCH",version="v1"} 25
apiserver_longrunning_requests{component="apiserver",group="",resource="endpoints",scope="cluster",subresource="",verb="WATCH",version="v1"} 2
```

### Try /metrics access from pod using "default" Service Account

Create deployment:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created
```

To request /metrics from api server target the kubernetes svc in default namespace (its the api server service):
```
$ k get svc kubernetes
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.255.0.1   <none>        443/TCP   56d

$ k get svc kubernetes -o yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2025-01-26T07:24:04Z"
  labels:
    component: apiserver
    provider: kubernetes
  name: kubernetes
  namespace: default
  resourceVersion: "230"
  uid: 30ed3202-ea1d-4a94-96a2-69ef2eb3e595
spec:
  clusterIP: 10.255.0.1
  clusterIPs:
  - 10.255.0.1
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 6443
  sessionAffinity: None
  type: ClusterIP

$ k cluster-info
Kubernetes control plane is running at https://10.128.0.16:6443
CoreDNS is running at https://10.128.0.16:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Try to exec into pod to reach this service:
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

root@http-server-5c4c6474b5-2jf8g:~# export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@http-server-5c4c6474b5-2jf8g:~# curl -k --header "Authorization: Bearer $TOKEN" https://kubernetes.default/metrics
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/metrics\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```


Check using auth can-i:
```
$ k auth whoami
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=8979e3d39e1d81acc4258cf55cea1933d20d32a0f05df627d7a4edfc04cfb345]

$ kubectl auth can-i get /metrics
yes

$ kubectl auth can-i get /metrics --as=kubernetes-admin --as-group=system:masters 
yes

$ kubectl auth can-i get /metrics --as=system:serviceaccount:default:default
no
```


# Service account with kube-api-server /metrics endpoint access


Initially tried to use Role and RoleBinding to namespace the role:
```
$ kubectl apply -f sa-monitoring.yaml 
serviceaccount/monitoring created
rolebinding.rbac.authorization.k8s.io/view-api-server-metrics created
The Role "view-api-server-metrics" is invalid: rules[0].nonResourceURLs: Invalid value: []string{"/metrics"}: namespaced rules cannot apply to non-resource URLs
```

So the rules have to use ClusterRole and ClusterRoleBinding, fix and apply again:












# Install metrics-server

Initially confused /metrics api with metrics.k8s.io api group that provides resource monitoring for Horizontal / Vertical pod autoscalers. 

Below are instructions regarding its install.

### About metrics.k8s.io api

Metrics pipeline overview: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

Metrics server implementation to provide `metrics.k8s.io` api: https://github.com/kubernetes-sigs/metrics-server

Metrics format exposed by metrics-server: https://kubernetes.io/docs/reference/instrumentation/metrics/

See also: https://kubernetes.io/docs/reference/external-api/metrics.v1beta1/


Check if metrics api is already installed:
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

Note: docs state that right now kubelet is exposing metric unsecurely: https://github.com/kubernetes-sigs/metrics-server/blob/master/FAQ.md#how-to-run-metrics-server-securely

However get "401 Unauthorized" when trying metrics without auth, so maybe its ok:
```
$ curl -v -k https://158.160.61.136:10250/metrics/resource
*   Trying 158.160.61.136:10250...
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / x25519 / RSASSA-PSS
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=master@1737876213
*  start date: Jan 26 06:23:33 2025 GMT
*  expire date: Jan 26 06:23:33 2026 GMT
*  issuer: CN=master-ca@1737876213
*  SSL certificate verify result: self-signed certificate in certificate chain (19), continuing anyway.
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
*   Certificate level 1: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* Connected to 158.160.61.136 (158.160.61.136) port 10250
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://158.160.61.136:10250/metrics/resource
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: 158.160.61.136:10250]
* [HTTP/2] [1] [:path: /metrics/resource]
* [HTTP/2] [1] [user-agent: curl/8.12.1]
* [HTTP/2] [1] [accept: */*]
> GET /metrics/resource HTTP/2
> Host: 158.160.61.136:10250
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
< HTTP/2 401 
< content-type: text/plain; charset=utf-8
< content-length: 12
< date: Sun, 23 Mar 2025 07:08:45 GMT
< 
* Connection #0 to host 158.160.61.136 left intact
Unauthorized%
```


### Try kube api server access from pod using "default" Service Account

Create deployment:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created
```

Try to access kube api server with curl from debug container:
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

root@http-server-5c4c6474b5-2jf8g:~# export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@http-server-5c4c6474b5-2jf8g:~# curl -k --header "Authorization: Bearer $TOKEN" https://metrics-server.default/metrics
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/metrics\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
```


