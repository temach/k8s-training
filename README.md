# Install monitoring stack

See https://opentelemetry.io/ecosystem/vendors/ for projects that support OpenTelemetry.

Demo helm chart that installs components: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo
and docs for the helm chart: https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/

A good choice: Jaeger, FluentBit + Opensearch, Prometheus, Grafana

Registry of library/app integrations with Otel: https://opentelemetry.io/ecosystem/registry/?s=apache


### Install Prometheus

Take helmfile from kubernetes-istio branch, it has already been done. Just disable all components except for prometheus tsdb server. 


### Install OpenTelemetry Collector

Strictly speaking collector is not necessary, metrics/logs/traces can be send directly to the different backends in OTEL format,
but collector is nice and it can aggreagate logs (like fluentd)
and it can both scrape metrics and receive pushed metrics instead of prometheus, see: https://opentelemetry.io/docs/platforms/kubernetes/collector/components/#prometheus-receiver

Run in daemonset mode, because that allows to collect logs, add toleration to run on control-plane nodes.

However drawback is that to collect hostmetrics otel-collector mounts host root filesystem into container,
and unlike prometheus-node-exporter otel collector accepts input making it easier to take over. Therefore maybe its best to avoid running it on master nodes.

Helm charts (including Demo) https://opentelemetry.io/docs/platforms/kubernetes/helm/ and
install guide for k8s https://opentelemetry.io/docs/platforms/kubernetes/helm/collector/#installing-the-chart

Use otel collector presets https://opentelemetry.io/docs/platforms/kubernetes/helm/collector/#presets for configuration.
More info about what each preset activates and how it works: https://opentelemetry.io/docs/platforms/kubernetes/collector/components/

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

Enable presets in otel config, enable our custom config.
Note that otel port use hostPort directive, so collector is easier to access from pods on the node (see https://opentelemetry.io/docs/security/config-best-practices/#kubernetes ) 
Disable non-otel ports, however note that services are still accessiable from outside the container (containerPort is not a security boundary):
```
# helmfile apply

$ k get cm -n otel otel-collector-opentelemetry-collector-agent -o yaml
apiVersion: v1
data:
  relay: |
    exporters:
      debug: {}
      otlphttp/prometheus:
        encoding: proto
        endpoint: http://prometheus-server.prometheus:80/api/v1/otlp
    extensions:
      health_check:
        endpoint: ${env:MY_POD_IP}:13133
      zpages:
        endpoint: 0.0.0.0:55679
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
      - zpages
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
          - otlphttp/prometheus
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
        logs:
          level: DEBUG
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
  resourceVersion: "1017480"
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

### Verify that otel collector collect logs

Increase debug log level verbosity and enable zpages extension (a web gui to see collector state) see: https://opentelemetry.io/docs/collector/troubleshooting/


At this point I noticed errors in otel-collector regarding TLS connection to kubelet:
```
2025-03-27T16:33:52.164Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T16:33:58.388Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T16:34:02.202Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T16:34:08.366Z	error	scraperhelper@v0.121.0/obs_metrics.go:61	Error scraping metrics	{"otelcol.component.id": "kubeletstats", "otelcol.component.kind": "Receiver", "otelcol.signal": "metrics", "error": "Get \"https://10.128.0.25:10250/stats/summary\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.25 because it doesn't contain any IP SANs"}
```

This error already came up while installing kubernetes metrics-server, and there solution was to disable TLS, but this time, instead lets fix TLS in cluster.
For the fix details see "serverTLSBootstrap: true" in kubernetes-prod branch. 

As a result error is gone:
```
2025-03-27T20:31:52.139Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:31:58.563Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:02.179Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:32:08.406Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:09.410Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 15, "metrics": 122, "data points": 124}
2025-03-27T20:32:12.220Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:32:18.444Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:22.262Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:32:28.486Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:29.490Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 15, "metrics": 122, "data points": 124}
2025-03-27T20:32:32.101Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:32:38.522Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:42.137Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
2025-03-27T20:32:48.562Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 6, "metrics": 19, "data points": 91}
2025-03-27T20:32:49.563Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 15, "metrics": 122, "data points": 124}
2025-03-27T20:32:52.175Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 36, "data points": 59}
```


Enable zpages extension. REMEMBER TO ALSO LIST zpages UNDER "config.service.extensions" ELSE WILL NOT START.

Verify that metrics are collected, examine zpages main page at http://localhost:55679/debug/servicez and http://localhost:55679/debug/tracez:
```
$ cat helmfile.yaml
...
        config:
          extensions:
            # ui to debug collector: https://github.com/open-telemetry/opentelemetry-collector/tree/main/extension/zpagesextension
            # must bind to 0.0.0.0 else breaks kubectl port-forward
            zpages:
              endpoint: 0.0.0.0:55679

          service:
            extensions: 
            - zpages
...


$ k get pods -n otel -o wide
NAME                                                 READY   STATUS    RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
otel-collector-opentelemetry-collector-agent-cxh9z   1/1     Running   0          20s   10.244.3.77    worker3   <none>           <none>
otel-collector-opentelemetry-collector-agent-ggz5j   1/1     Running   0          24s   10.244.1.227   worker1   <none>           <none>
otel-collector-opentelemetry-collector-agent-ktk77   1/1     Running   0          22s   10.244.2.69    worker2   <none>           <none>


$ k port-forward -n otel pod/otel-collector-opentelemetry-collector-agent-ggz5j 55679:55679
Forwarding from 127.0.0.1:55679 -> 55679
Forwarding from [::1]:55679 -> 55679
Handling connection for 55679


$ curl -v http://localhost:55679/debug/servicez 
* Host localhost:55679 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:55679...
* Connected to localhost (::1) port 55679
* using HTTP/1.x
> GET /debug/servicez HTTP/1.1
> Host: localhost:55679
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Content-Type: text/html; charset=utf-8
< Date: Sat, 29 Mar 2025 19:42:18 GMT
< Transfer-Encoding: chunked
< 
<!DOCTYPE html>
<html lang="en"><head>
    <meta charset="utf-8">
    <title>Service otelcol-contrib</title>
    <link rel="shortcut icon" href="https://opentelemetry.io/favicons/favicon.ico"/>
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
    <script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>
</head>
<body>
<h2>Service otelcol-contrib</h2><b>Build Info:</b>
<table style="border-spacing: 0">
    
    
            <tr style="background: #eee">
        <td style="text-align: center"><b>Command</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">otelcol-contrib</td>
        </tr>
    
            <tr><td style="text-align: center"><b>Description</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">OpenTelemetry Collector Contrib</td>
        </tr>
    
            <tr style="background: #eee">
        <td style="text-align: center"><b>Version</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">0.121.0</td>
        </tr>
    
</table><b>Runtime Info:</b>
<table style="border-spacing: 0">
    
    
            <tr style="background: #eee">
        <td style="text-align: center"><b>StartTimestamp</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">2025-03-29 19:37:46.373744983 &#43;0000 UTC m=&#43;0.077113230</td>
        </tr>
    
            <tr><td style="text-align: center"><b>Go</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">go1.24.0</td>
        </tr>
    
            <tr style="background: #eee">
        <td style="text-align: center"><b>OS</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">linux</td>
        </tr>
    
            <tr><td style="text-align: center"><b>Arch</b></td>
        <td>&nbsp;&nbsp;|&nbsp;&nbsp;</td>
        <td style="text-align: center">amd64</td>
        </tr>
    
</table><h6><a href="pipelinez">Pipelines</a></h6><h6><a href="extensionz">Extensions</a></h6><h6><a href="featurez">Features</a></h6></body>
* Connection #0 to host localhost left intact
</html>

```

zpages /tracez shows otel spans within the program, nice to view e.g. tight loop performance or to verify POST to prometheus is 200 (note that only last 10 items per bucket are shown):

![image](https://github.com/user-attachments/assets/544d55de-be02-4606-aecf-e1c921056edb)


### Export metrics to prometheus

So otel collects metrics being collected, now configure exporter to prometheus tsdb and add it to metrics pipeline.
Using Prometheus as OpenTelemetry backend configuration: https://prometheus.io/docs/guides/opentelemetry/

See Demo configuration: https://github.com/open-telemetry/opentelemetry-helm-charts/blob/main/charts/opentelemetry-demo/values.yaml#L724
See official exporters doc: https://opentelemetry.io/docs/collector/configuration/#exporters 

Add configuration for exporting metrics, be careful not to messup configuration added by presets:
```
    config:
      exporters:
        # https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/otlphttpexporter
        otlphttp/prometheus:
          # prometheus needs http + protobuf targeting endpoint /api/v1/otlp/v1/metrics, see: https://prometheus.io/docs/guides/opentelemetry/
          endpoint: http://prometheus-server.prometheus:80/api/v1/otlp
          encoding: proto
    
      service:
        pipelines:
          metrics:
            exporters:
            - debug
            - otlphttp/prometheus
```


Check if configuration applied, erase any previous prometheus data (scale down prometheus and "rm -rf" PV data), remove prom scrape rules and restart:
```

$ k port-forward -n prometheus svc/prometheus-server 9090:http
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090

$ curl http://localhost:9090/api/v1/status/tsdb | jq
{
  "status": "success",
  "data": {
    "headStats": {
      "numSeries": 801,
      "numLabelPairs": 467,
      "chunkCount": 801,
      "minTime": 1743161259015,
      "maxTime": 1743161319015
    },
    "seriesCountByMetricName": [
      {
        "name": "prometheus_http_request_duration_seconds_bucket",
        "value": 120
      },
      {
        "name": "prometheus_http_response_size_bytes_bucket",
        "value": 108
      },
      {
        "name": "prometheus_http_requests_total",
        "value": 57
      },
      {
        "name": "prometheus_sd_kubernetes_events_total",
        "value": 18
      },
      {
        "name": "prometheus_tsdb_compaction_duration_seconds_bucket",
        "value": 15
      },
      {
        "name": "prometheus_tsdb_compaction_chunk_size_bytes_bucket",
        "value": 13
      },
      {
        "name": "prometheus_tsdb_compaction_chunk_samples_bucket",
        "value": 13
      },
      {
        "name": "prometheus_http_request_duration_seconds_count",
        "value": 12
      },
      {
        "name": "prometheus_engine_query_duration_seconds",
        "value": 12
      },
      {
        "name": "prometheus_http_response_size_bytes_count",
        "value": 12
      }
    ],
    "labelValueCountByLabelName": [
      {
        "name": "__name__",
        "value": 279
      },
      {
        "name": "le",
        "value": 79
      },
      {
        "name": "handler",
        "value": 56
      },
      {
        "name": "quantile",
        "value": 9
      },
      {
        "name": "role",
        "value": 6
      },
      {
        "name": "slice",
        "value": 4
      },
      {
        "name": "code",
        "value": 4
      },
      {
        "name": "reason",
        "value": 4
      },
      {
        "name": "event",
        "value": 3
      },
      {
        "name": "call",
        "value": 2
      }
    ],
    "memoryInBytesByLabelName": [
      {
        "name": "__name__",
        "value": 40275
      },
      {
        "name": "instance",
        "value": 19224
      },
      {
        "name": "job",
        "value": 12015
      },
      {
        "name": "handler",
        "value": 7519
      },
      {
        "name": "le",
        "value": 4035
      },
      {
        "name": "quantile",
        "value": 671
      },
      {
        "name": "code",
        "value": 540
      },
      {
        "name": "slice",
        "value": 355
      },
      {
        "name": "scrape_job",
        "value": 308
      },
      {
        "name": "dialer_name",
        "value": 301
      }
    ],
    "seriesCountByLabelValuePair": [
      {
        "name": "instance=localhost:9090",
        "value": 801
      },
      {
        "name": "job=prometheus",
        "value": 801
      },
      {
        "name": "__name__=prometheus_http_request_duration_seconds_bucket",
        "value": 120
      },
      {
        "name": "__name__=prometheus_http_response_size_bytes_bucket",
        "value": 108
      },
      {
        "name": "__name__=prometheus_http_requests_total",
        "value": 57
      },
      {
        "name": "code=200",
        "value": 57
      },
      {
        "name": "le=+Inf",
        "value": 37
      },
      {
        "name": "handler=/",
        "value": 25
      },
      {
        "name": "handler=/api/v1/label/:name/values",
        "value": 24
      },
      {
        "name": "handler=/metrics",
        "value": 24
      }
    ]
  }
}


$ k debug -it --profile=sysadmin --image=nicolaka/netshoot:v0.13 -n otel --target=opentelemetry-collector otel-collector-opentelemetry-collector-agent-98qhr

 otel-collector-opentelemetry-collector-agent-98qhr  ~  curl -v http://prometheus-server.prometheus:80/api/v1/otlp/v1/metrics 
* Host prometheus-server.prometheus:80 was resolved.
* IPv6: (none)
* IPv4: 10.255.31.79
*   Trying 10.255.31.79:80...
* Connected to prometheus-server.prometheus (10.255.31.79) port 80
> GET /api/v1/otlp/v1/metrics HTTP/1.1
> Host: prometheus-server.prometheus
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 405 Method Not Allowed
< Allow: OPTIONS, POST
< Content-Type: text/plain; charset=utf-8
< X-Content-Type-Options: nosniff
< Date: Fri, 28 Mar 2025 15:09:15 GMT
< Content-Length: 19
< 
Method Not Allowed
* Connection #0 to host prometheus-server.prometheus left intact
```

So the right url to reach prom should be "http://prometheus-server.prometheus:80/api/v1/otlp/v1/metrics"

Fix url and verify that otel metrics reach prometheus:
```
$ k port-forward -n prometheus svc/prometheus-server 9090:http
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090


$ curl http://localhost:9090/api/v1/status/tsdb | jq
{
  "status": "success",
  "data": {
    "headStats": {
      "numSeries": 1315,
      "numLabelPairs": 671,
      "chunkCount": 2902,
      "minTime": 1743270519015,
      "maxTime": 1743279055618
    },
    "seriesCountByMetricName": [
      {
        "name": "otelcol_processor_batch_batch_send_size_bucket",
        "value": 138
      },
      {
        "name": "prometheus_http_request_duration_seconds_bucket",
        "value": 80
      },
      {
        "name": "prometheus_http_response_size_bytes_bucket",
        "value": 72
      },
      {
        "name": "prometheus_http_requests_total",
        "value": 57
      },
      {
        "name": "otelcol_scraper_errored_metric_points_total",
        "value": 42
      },
      {
        "name": "otelcol_scraper_scraped_metric_points_total",
        "value": 42
      },
      {
        "name": "otelcol_receiver_refused_metric_points_total",
        "value": 18
      },
      {
        "name": "otelcol_receiver_accepted_metric_points_total",
        "value": 18
      },
      {
        "name": "prometheus_sd_kubernetes_events_total",
        "value": 18
      },
      {
        "name": "system_cpu_time_seconds_total",
        "value": 16
      }
    ],
    "labelValueCountByLabelName": [
      {
        "name": "__name__",
        "value": 364
      },
      {
        "name": "le",
        "value": 101
      },
      {
        "name": "handler",
        "value": 56
      },
      {
        "name": "state",
        "value": 27
      },
      {
        "name": "quantile",
        "value": 9
      },
      {
        "name": "scraper",
        "value": 7
      },
      {
        "name": "instance",
        "value": 7
      },
      {
        "name": "server_address",
        "value": 6
      },
      {
        "name": "device",
        "value": 6
      },
      {
        "name": "service_instance_id",
        "value": 6
      }
    ],
    "memoryInBytesByLabelName": [
      {
        "name": "__name__",
        "value": 64539
      },
      {
        "name": "instance",
        "value": 39234
      },
      {
        "name": "service_instance_id",
        "value": 24795
      },
      {
        "name": "job",
        "value": 20295
      },
      {
        "name": "service_name",
        "value": 12615
      },
      {
        "name": "service_version",
        "value": 10584
      },
      {
        "name": "handler",
        "value": 4943
      },
      {
        "name": "le",
        "value": 4459
      },
      {
        "name": "processor",
        "value": 3453
      },
      {
        "name": "receiver",
        "value": 2566
      }
    ],
    "seriesCountByLabelValuePair": [
      {
        "name": "instance=localhost:9090",
        "value": 709
      },
      {
        "name": "job=prometheus",
        "value": 709
      },
      {
        "name": "job=otelcol-contrib",
        "value": 483
      },
      {
        "name": "service_version=0.121.0",
        "value": 441
      },
      {
        "name": "service_name=otelcol-contrib",
        "value": 435
      },
      {
        "name": "processor=batch",
        "value": 162
      },
      {
        "name": "__name__=otelcol_processor_batch_batch_send_size_bucket",
        "value": 138
      },
      {
        "name": "instance=a6971ef1-555b-46a7-ab37-473ea0ba6438",
        "value": 88
      },
      {
        "name": "receiver=hostmetrics",
        "value": 84
      },
      {
        "name": "__name__=prometheus_http_request_duration_seconds_bucket",
        "value": 80
      }
    ]
  }
}
```

Exported metrics have an instance id which is a UUID identifier "service.instance.id". Read more about it here: https://opentelemetry.io/docs/specs/semconv/attributes-registry/service/#service-instance-id


