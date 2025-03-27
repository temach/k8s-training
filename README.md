# Install monitoring stack

See https://opentelemetry.io/ecosystem/vendors/ for projects that support OpenTelemetry.

Demo helm chart that installs components: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo
and docs for the helm chart: https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/

A good choice: Jaeger, FluentBit + Opensearch, Prometheus, Grafana

Registry of library/app integrations with Otel: https://opentelemetry.io/ecosystem/registry/?s=apache


### Install Prometheus

Take helmfile from kubernetes-istio branch, it has already been done.


### Install OpenTelemetry Collector

Strictly speaking collector is not necessary, metrics/logs/traces can be send directly to the different backends in OTEL format,
but collector is nice and it can aggreagate logs (like fluentd)
and it can both scrape metrics and receive pushed metrics instead of prometheus, see: https://opentelemetry.io/docs/platforms/kubernetes/collector/components/#prometheus-receiver

Run in daemonset mode, because that allows to collect logs, add toleration to run on control-plane nodes.

However drawback is that to collect hostmetrics otel-collector mounts host root filesystem into container,
and unlike prometheus-node-exporter otel collector accepts input making it easier to take over. Therefore maybe its best to avoid running it on master nodes.

Github repo: https://github.com/open-telemetry/opentelemetry-collector

Helm charts (including Demo) https://opentelemetry.io/docs/platforms/kubernetes/helm/ and
install guide https://opentelemetry.io/docs/platforms/kubernetes/helm/collector/#installing-the-chart


Different flavours of collector: see https://github.com/open-telemetry/opentelemetry-collector-releases and https://github.com/orgs/open-telemetry/packages?repo_name=opentelemetry-collector-releases

- The fat flavour with everything is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib
  image.repository="otel/opentelemetry-collector-contrib"

- The flavour for k8s is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-k8s
  image.repository="otel/opentelemetry-collector-k8s"

- The super-minimalist flavour is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-otlp
  image.repository="otel/opentelemetry-collector-contrib"

- Lastly is the classic older image: image.repository="otel/opentelemetry-collector"



```
# helmfile apply
Upgrading release=otel-collector, chart=open-telemetry/opentelemetry-collector, namespace=otel
Upgrading release=prometheus, chart=prometheus-community/prometheus, namespace=prometheus
Release "otel-collector" does not exist. Installing it now.
NAME: otel-collector
LAST DEPLOYED: Thu Mar 27 13:31:01 2025
NAMESPACE: otel
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
[WARNING] No resource limits or requests were set. Consider setter resource requests and limits for your collector(s) via the `resources` field.

[WARNING] "useGOMEMLIMIT" is enabled but memory limits have not been supplied so the GOMEMLIMIT env var could not be added. Solve this problem by setting resources.limits.memory or disabling useGOMEMLIMIT

Listing releases matching ^otel-collector$
otel-collector	otel     	1       	2025-03-27 13:31:01.455589295 +0000 UTC	deployed	opentelemetry-collector-0.119.0	0.121.0    

Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Thu Mar 27 13:31:02 2025
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
prometheus	prometheus	1       	2025-03-27 13:31:02.018088602 +0000 UTC	deployed	prometheus-27.5.1	v3.2.1     


UPDATED RELEASES:
NAME             NAMESPACE    CHART                                    VERSION   DURATION
otel-collector   otel         open-telemetry/opentelemetry-collector   0.119.0         2s
prometheus       prometheus   prometheus-community/prometheus          27.5.1          3s


$ k get pods -A -o wide
NAMESPACE      NAME                                                 READY   STATUS    RESTARTS       AGE   IP             NODE      NOMINATED NODE   READINESS GATES
default        http-server-568587b657-xb76p                         1/1     Running   0              20m   10.244.1.193   worker1   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh                                1/1     Running   14 (30m ago)   10d   10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4                                1/1     Running   28 (30m ago)   10d   10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7                                1/1     Running   15 (32m ago)   10d   10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk                                1/1     Running   14 (30m ago)   10d   10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-9fv2f                             1/1     Running   1 (32m ago)    11h   10.244.1.188   worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt                             1/1     Running   20 (31m ago)   29d   10.244.0.33    master    <none>           <none>
kube-system    etcd-master                                          1/1     Running   26 (31m ago)   59d   10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master                                1/1     Running   26 (31m ago)   59d   10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master                       1/1     Running   28 (70s ago)   59d   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                                     1/1     Running   13 (32m ago)   13d   10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                                     1/1     Running   12 (31m ago)   13d   10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                                     1/1     Running   9 (32m ago)    10d   10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                                     1/1     Running   10 (32m ago)   10d   10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master                                1/1     Running   23 (65s ago)   29d   10.128.0.16    master    <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-2zjcs   1/1     Running   0              39s   10.244.3.54    worker3   <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-58t2r   1/1     Running   0              41s   10.244.1.194   worker1   <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-crtk5   1/1     Running   0              36s   10.244.2.41    worker2   <none>           <none>
prometheus     prometheus-kube-state-metrics-5bd466f7f6-psfnd       1/1     Running   0              27m   10.244.2.40    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-5wlvj            1/1     Running   0              27m   10.128.0.26    worker2   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-bgkwv            1/1     Running   0              27m   10.128.0.16    master    <none>           <none>
prometheus     prometheus-prometheus-node-exporter-dvskq            1/1     Running   0              27m   10.128.0.3     worker3   <none>           <none>
prometheus     prometheus-prometheus-node-exporter-mtx78            1/1     Running   0              27m   10.128.0.25    worker1   <none>           <none>
prometheus     prometheus-server-88cb5cb78-gktwj                    2/2     Running   0              27m   10.244.1.192   worker1   <none>           <none>


$ k debug -it --profile=sysadmin --image=nicolaka/netshoot:v0.13 -n otel --target=opentelemetry-collector otel-collector-opentelemetry-collector-agent-hmbk8

otel-collector-opentelemetry-collector-agent-hmbk8  ~  ps  
PID   USER     TIME  COMMAND
    1 10001     0:00 /otelcol-contrib --config=/conf/relay.yaml
   15 root      0:01 zsh
  153 root      0:00 ps

 otel-collector-opentelemetry-collector-agent-hmbk8  ~  env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=netshoot
TERM=xterm
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.255.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.255.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=10.255.0.1
KUBERNETES_SERVICE_HOST=10.255.0.1
KUBERNETES_SERVICE_PORT=443
HOME=/root
LOGNAME=root
SHLVL=1
PWD=/root
OLDPWD=/root
ZSH=/root/.oh-my-zsh
PAGER=less
LESS=-R
LSCOLORS=Gxfxcxdxbxegedabagacad
LS_COLORS=di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43

otel-collector-opentelemetry-collector-agent-hmbk8  ~  cat /proc/1/root/conf/relay.yaml
exporters:
  debug: {}
extensions:
  health_check:
    endpoint: ${env:MY_POD_IP}:13133
processors:
  batch: {}
  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25
receivers:
  jaeger:
    protocols:
      grpc:
        endpoint: ${env:MY_POD_IP}:14250
      thrift_compact:
        endpoint: ${env:MY_POD_IP}:6831
      thrift_http:
        endpoint: ${env:MY_POD_IP}:14268
  otlp:
    protocols:
      grpc:
        endpoint: ${env:MY_POD_IP}:4317
      http:
        endpoint: ${env:MY_POD_IP}:4318
  prometheus:
    config:
      scrape_configs:
      - job_name: opentelemetry-collector
        scrape_interval: 10s
        static_configs:
        - targets:
          - ${env:MY_POD_IP}:8888
  zipkin:
    endpoint: ${env:MY_POD_IP}:9411
service:
  extensions:
  - health_check
  pipelines:
    logs:
      exporters:
      - debug
      processors:
      - memory_limiter
      - batch
      receivers:
      - otlp
    metrics:
      exporters:
      - debug
      processors:
      - memory_limiter
      - batch
      receivers:
      - otlp
      - prometheus
    traces:
      exporters:
      - debug
      processors:
      - memory_limiter
      - batch
      receivers:
      - otlp
      - jaeger
      - zipkin
  telemetry:
    metrics:
      address: ${env:MY_POD_IP}:8888
```


Enable otel collector presets https://opentelemetry.io/docs/platforms/kubernetes/helm/collector/#presets and redeploy.


Also disable prometheus-node-exporter and prometheus-kube-state-metrics and disable non-otel collectors:

```
# helmfile apply
Upgrading release=otel-collector, chart=open-telemetry/opentelemetry-collector, namespace=otel
Upgrading release=prometheus, chart=prometheus-community/prometheus, namespace=prometheus
Release "otel-collector" has been upgraded. Happy Helming!
NAME: otel-collector
LAST DEPLOYED: Thu Mar 27 16:11:41 2025
NAMESPACE: otel
STATUS: deployed
REVISION: 5
TEST SUITE: None
NOTES:
[WARNING] No resource limits or requests were set. Consider setter resource requests and limits for your collector(s) via the `resources` field.

[WARNING] "useGOMEMLIMIT" is enabled but memory limits have not been supplied so the GOMEMLIMIT env var could not be added. Solve this problem by setting resources.limits.memory or disabling useGOMEMLIMIT

Listing releases matching ^otel-collector$
otel-collector	otel     	5       	2025-03-27 16:11:41.772383662 +0000 UTC	deployed	opentelemetry-collector-0.119.0	0.121.0    

Release "prometheus" has been upgraded. Happy Helming!
NAME: prometheus
LAST DEPLOYED: Thu Mar 27 16:11:41 2025
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



For more information on running Prometheus, visit:
https://prometheus.io/

Listing releases matching ^prometheus$
prometheus	prometheus	2       	2025-03-27 16:11:41.874115738 +0000 UTC	deployed	prometheus-27.5.1	v3.2.1     


UPDATED RELEASES:
NAME             NAMESPACE    CHART                                    VERSION   DURATION
otel-collector   otel         open-telemetry/opentelemetry-collector   0.119.0         3s
prometheus       prometheus   prometheus-community/prometheus          27.5.1          4s


# k get pods -A -o wide
NAMESPACE      NAME                                                 READY   STATUS    RESTARTS        AGE     IP             NODE      NOMINATED NODE   READINESS GATES
default        http-server-568587b657-xb76p                         1/1     Running   0               163m    10.244.1.193   worker1   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh                                1/1     Running   14 (173m ago)   10d     10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4                                1/1     Running   28 (173m ago)   10d     10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7                                1/1     Running   15 (175m ago)   10d     10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk                                1/1     Running   14 (173m ago)   10d     10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-9fv2f                             1/1     Running   1 (175m ago)    14h     10.244.1.188   worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt                             1/1     Running   20 (174m ago)   29d     10.244.0.33    master    <none>           <none>
kube-system    etcd-master                                          1/1     Running   26 (174m ago)   59d     10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master                                1/1     Running   26 (174m ago)   59d     10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master                       1/1     Running   29 (140m ago)   59d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                                     1/1     Running   13 (175m ago)   13d     10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                                     1/1     Running   12 (174m ago)   13d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                                     1/1     Running   9 (175m ago)    10d     10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                                     1/1     Running   10 (175m ago)   10d     10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master                                1/1     Running   24 (139m ago)   29d     10.128.0.16    master    <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-b7sjt   1/1     Running   0               9m12s   10.244.1.197   worker1   <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-fpds8   1/1     Running   0               9m15s   10.244.2.44    worker2   <none>           <none>
otel           otel-collector-opentelemetry-collector-agent-hmzdf   1/1     Running   0               9m10s   10.244.3.56    worker3   <none>           <none>
prometheus     prometheus-server-6cc7dd8658-2t89x                   2/2     Running   0               9m14s   10.244.1.196   worker1   <none>           <none>


$ k get cm -n otel otel-collector-opentelemetry-collector-agent -o yaml
apiVersion: v1
data:
  relay: |
    exporters:
      debug: {}
    extensions:
      health_check:
        endpoint: ${env:MY_POD_IP}:13133
    processors:
      batch: {}
      k8sattributes:
        extract:
          metadata:
          - k8s.namespace.name
          - k8s.deployment.name
          - k8s.statefulset.name
          - k8s.daemonset.name
          - k8s.cronjob.name
          - k8s.job.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - k8s.pod.start_time
        filter:
          node_from_env_var: K8S_NODE_NAME
        passthrough: false
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: connection
      memory_limiter:
        check_interval: 5s
        limit_percentage: 80
        spike_limit_percentage: 25
    receivers:
      filelog:
        exclude:
        - /var/log/pods/otel_otel-collector-opentelemetry-collector*_*/opentelemetry-collector/*.log
        include:
        - /var/log/pods/*/*/*.log
        include_file_name: false
        include_file_path: true
        operators:
        - id: container-parser
          max_log_size: 102400
          type: container
        retry_on_failure:
          enabled: true
        start_at: end
      hostmetrics:
        collection_interval: 10s
        root_path: /hostfs
        scrapers:
          cpu: null
          disk: null
          filesystem:
            exclude_fs_types:
              fs_types:
              - autofs
              - binfmt_misc
              - bpf
              - cgroup2
              - configfs
              - debugfs
              - devpts
              - devtmpfs
              - fusectl
              - hugetlbfs
              - iso9660
              - mqueue
              - nsfs
              - overlay
              - proc
              - procfs
              - pstore
              - rpc_pipefs
              - securityfs
              - selinuxfs
              - squashfs
              - sysfs
              - tracefs
              match_type: strict
            exclude_mount_points:
              match_type: regexp
              mount_points:
              - /dev/*
              - /proc/*
              - /sys/*
              - /run/k3s/containerd/*
              - /var/lib/docker/*
              - /var/lib/kubelet/*
              - /snap/*
          load: null
          memory: null
          network: null
      jaeger:
        protocols:
          grpc:
            endpoint: ${env:MY_POD_IP}:14250
          thrift_compact:
            endpoint: ${env:MY_POD_IP}:6831
          thrift_http:
            endpoint: ${env:MY_POD_IP}:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 20s
        endpoint: ${env:K8S_NODE_IP}:10250
      otlp:
        protocols:
          grpc:
            endpoint: ${env:MY_POD_IP}:4317
          http:
            endpoint: ${env:MY_POD_IP}:4318
      prometheus:
        config:
          scrape_configs:
          - job_name: opentelemetry-collector
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${env:MY_POD_IP}:8888
      zipkin:
        endpoint: ${env:MY_POD_IP}:9411
    service:
      extensions:
      - health_check
      pipelines:
        logs:
          exporters:
          - debug
          processors:
          - k8sattributes
          - memory_limiter
          - batch
          receivers:
          - otlp
          - filelog
        metrics:
          exporters:
          - debug
          processors:
          - k8sattributes
          - memory_limiter
          - batch
          receivers:
          - otlp
          - prometheus
          - hostmetrics
          - kubeletstats
        traces:
          exporters:
          - debug
          processors:
          - k8sattributes
          - memory_limiter
          - batch
          receivers:
          - otlp
          - jaeger
          - zipkin
      telemetry:
        metrics:
          address: ${env:MY_POD_IP}:8888
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: otel-collector
    meta.helm.sh/release-namespace: otel
  creationTimestamp: "2025-03-27T13:31:01Z"
  labels:
    app.kubernetes.io/component: agent-collector
    app.kubernetes.io/instance: otel-collector
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: opentelemetry-collector
    app.kubernetes.io/version: 0.121.0
    helm.sh/chart: opentelemetry-collector-0.119.0
  name: otel-collector-opentelemetry-collector-agent
  namespace: otel
  resourceVersion: "912329"
  uid: b9a96297-8edc-4371-9c82-b23fe789fea5


$ k get -n otel pod otel-collector-opentelemetry-collector-agent-hmzdf -o yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    checksum/config: 4ccd352f7fa79349fbf5699dcb0baf0a254e3892ea01bd65bdc557a15d316efb
  creationTimestamp: "2025-03-27T16:11:48Z"
  generateName: otel-collector-opentelemetry-collector-agent-
  labels:
    app.kubernetes.io/instance: otel-collector
    app.kubernetes.io/name: opentelemetry-collector
    component: agent-collector
    controller-revision-hash: 555f85f955
    pod-template-generation: "5"
  name: otel-collector-opentelemetry-collector-agent-hmzdf
  namespace: otel
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: DaemonSet
    name: otel-collector-opentelemetry-collector-agent
    uid: d87ad252-6a78-4b7d-b9c1-5e9238c1a933
  resourceVersion: "912477"
  uid: 8dc87401-b570-4dc2-840d-7511dc9abf04
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchFields:
          - key: metadata.name
            operator: In
            values:
            - worker3
  containers:
  - args:
    - --config=/conf/relay.yaml
    env:
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: status.podIP
    - name: K8S_NODE_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: spec.nodeName
    - name: K8S_NODE_IP
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: status.hostIP
    image: otel/opentelemetry-collector-contrib:0.121.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 13133
        scheme: HTTP
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    name: opentelemetry-collector
    ports:
    - containerPort: 4317
      hostPort: 4317
      name: otlp
      protocol: TCP
    - containerPort: 4318
      hostPort: 4318
      name: otlp-http
      protocol: TCP
    readinessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 13133
        scheme: HTTP
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    resources: {}
    securityContext: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /conf
      name: opentelemetry-collector-configmap
    - mountPath: /var/log/pods
      name: varlogpods
      readOnly: true
    - mountPath: /var/lib/docker/containers
      name: varlibdockercontainers
      readOnly: true
    - mountPath: /hostfs
      mountPropagation: HostToContainer
      name: hostfs
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-djb5c
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: worker3
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: otel-collector-opentelemetry-collector
  serviceAccountName: otel-collector-opentelemetry-collector
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
  - effect: NoSchedule
    key: node.kubernetes.io/disk-pressure
    operator: Exists
  - effect: NoSchedule
    key: node.kubernetes.io/memory-pressure
    operator: Exists
  - effect: NoSchedule
    key: node.kubernetes.io/pid-pressure
    operator: Exists
  - effect: NoSchedule
    key: node.kubernetes.io/unschedulable
    operator: Exists
  volumes:
  - configMap:
      defaultMode: 420
      items:
      - key: relay
        path: relay.yaml
      name: otel-collector-opentelemetry-collector-agent
    name: opentelemetry-collector-configmap
  - hostPath:
      path: /var/log/pods
      type: ""
    name: varlogpods
  - hostPath:
      path: /var/lib/docker/containers
      type: ""
    name: varlibdockercontainers
  - hostPath:
      path: /
      type: ""
    name: hostfs
  - name: kube-api-access-djb5c
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```


Specifically note that only otel ports are available now:
```
    name: opentelemetry-collector
    ports:
    - containerPort: 4317
      hostPort: 4317
      name: otlp
      protocol: TCP
    - containerPort: 4318
      hostPort: 4318
      name: otlp-http
      protocol: TCP
```

