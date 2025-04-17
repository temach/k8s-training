# Install monitoring stack

See https://opentelemetry.io/ecosystem/vendors/ for projects that support OpenTelemetry.

Demo helm chart that installs components: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo
and docs for the helm chart: https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/

Choose: OTEL collector, Jaeger, Opensearch, Prometheus, Grafana

Registry of library/app integrations with Otel: https://opentelemetry.io/ecosystem/registry/?s=apache


# Setup Prometheus

Take helmfile from kubernetes-istio branch, it has already been done. Just disable all components except for prometheus tsdb server. 


# Setup OpenTelemetry Collector

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

See more about configuration: https://opentelemetry.io/docs/collector/configuration/#basics

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
      "numSeries": 1478,
      "numLabelPairs": 702,
      "chunkCount": 2724,
      "minTime": 1743281991962,
      "maxTime": 1743284191965
    },
    "seriesCountByMetricName": [
      {
        "name": "prometheus_http_request_duration_seconds_bucket",
        "value": 160
      },
      {
        "name": "prometheus_http_response_size_bytes_bucket",
        "value": 144
      },
      {
        "name": "otelcol_processor_batch_batch_send_size_bucket",
        "value": 69
      },
      {
        "name": "prometheus_http_requests_total",
        "value": 60
      },
      {
        "name": "otelcol_scraper_errored_metric_points_total",
        "value": 21
      },
      {
        "name": "otelcol_scraper_scraped_metric_points_total",
        "value": 21
      },
      {
        "name": "prometheus_sd_kubernetes_events_total",
        "value": 18
      },
      {
        "name": "prometheus_http_request_duration_seconds_sum",
        "value": 16
      },
      {
        "name": "prometheus_http_request_duration_seconds_count",
        "value": 16
      },
      {
        "name": "prometheus_http_response_size_bytes_sum",
        "value": 16
      }
    ],
    "labelValueCountByLabelName": [
      {
        "name": "__name__",
        "value": 376
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
        "name": "k8s.pod.name",
        "value": 12
      },
      {
        "name": "quantile",
        "value": 9
      },
      {
        "name": "k8s.container.name",
        "value": 7
      },
      {
        "name": "scraper",
        "value": 7
      },
      {
        "name": "role",
        "value": 6
      },
      {
        "name": "device",
        "value": 6
      }
    ],
    "memoryInBytesByLabelName": [
      {
        "name": "__name__",
        "value": 72086
      },
      {
        "name": "instance",
        "value": 33982
      },
      {
        "name": "job",
        "value": 18920
      },
      {
        "name": "service.instance.id",
        "value": 15105
      },
      {
        "name": "handler",
        "value": 10323
      },
      {
        "name": "k8s.pod.name",
        "value": 8566
      },
      {
        "name": "service.name",
        "value": 7685
      },
      {
        "name": "k8s.daemonset.name",
        "value": 6192
      },
      {
        "name": "service.version",
        "value": 5856
      },
      {
        "name": "k8s.namespace.name",
        "value": 5795
      }
    ],
    "seriesCountByLabelValuePair": [
      {
        "name": "job=prometheus",
        "value": 908
      },
      {
        "name": "instance=localhost:9090",
        "value": 908
      },
      {
        "name": "service.name=otelcol-contrib",
        "value": 265
      },
      {
        "name": "job=otelcol-contrib",
        "value": 265
      },
      {
        "name": "service.version=0.121.0",
        "value": 244
      },
      {
        "name": "__name__=prometheus_http_request_duration_seconds_bucket",
        "value": 160
      },
      {
        "name": "__name__=prometheus_http_response_size_bytes_bucket",
        "value": 144
      },
      {
        "name": "service.instance.id=44b16137-06a4-4f91-8bf9-534920dfbac5",
        "value": 89
      },
      {
        "name": "instance=44b16137-06a4-4f91-8bf9-534920dfbac5",
        "value": 89
      },
      {
        "name": "instance=10d32834-7f0a-460a-9241-df263d32420c",
        "value": 88
      }
    ]
  }
}
```

### Integrate apps with otel collector

See https://opentelemetry.io/docs/security/config-best-practices/#kubernetes
also see: https://github.com/open-telemetry/opentelemetry-collector/tree/main/receiver/otlpreceiver


Make a simple python flask app: https://opentelemetry.io/docs/languages/python/getting-started/
```
$ mkdir otel-getting-started
$ cd otel-getting-started
$ python3 -m venv venv
$ source ./venv/bin/activate\n
$ pip install -r requirements.txt

## copy source from https://opentelemetry.io/docs/languages/python/getting-started/#create-and-launch-an-http-server
$ vim app.py

$ flask run -p 8080
$ curl http://localhost:8080/rolldice

$ opentelemetry-bootstrap -a install

## copy source from https://opentelemetry.io/docs/languages/python/getting-started/#metrics
$ vim app.py

$ export OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
$ opentelemetry-instrument --traces_exporter console --metrics_exporter console --logs_exporter console --service_name dice-server flask run -p 8080
$ curl http://localhost:8080/rolldice

$ docker run -p 4317:4317 -v ./otel-collector-config.yaml:/etc/otelcol-contrib/config.yaml otel/opentelemetry-collector-contrib:0.121.0

$ pip install opentelemetry-exporter-otlp
$ export OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
$ opentelemetry-instrument --logs_exporter otlp --exporter_otlp_endpoint 0.0.0.0:4317 flask run -p 8080
```

Deploy it, and reconfigure metrics collector to stop its own metrics.

### Troubleshoot k8s attributes missing

When sending OTLP data to `hostPort` using the method described in kubernetes best practices https://opentelemetry.io/docs/security/config-best-practices/#kubernetes,
the default configuration of the `k8sattributes processor` ( https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/k8sattributesprocessor) 
prevents enriching pod OTLP data with k8s metadata. For example, the k8s.pod.name and the k8s.namespace.name attributes won't be included. If pod association rules aren't 
configured for the `k8sattributes` processor, resources are associated with metadata only by connection's IP Address.  This happens because the Collector sees this connection
as coming from the node and is unable to associate the pod with incoming OTLP data.

So in order for the flask app to get k8sattributes, a few options are available to trigger default pod association rules:
```
k8sattributes:
 pod_association:
  sources:
    # This rule associates all resources containing the 'k8s.pod.ip' attribute with the matching pods. If this attribute is not present in the resource, this rule will not be able to find the matching pod.
    - from: resource_attribute
      name: k8s.pod.ip
  sources:
    # This rule associates all resources containing the 'k8s.pod.uid' attribute with the matching pods. If this attribute is not present in the resource, this rule will not be able to find the matching pod.
    - from: resource_attribute
      name: k8s.pod.uid
  sources:
    # This rule will use the IP from the incoming connection from which the resource is received, and find the matching pod, based on the 'pod.status.podIP' of the observed pods
    - from: connection
```

1) run another otel-collector as deployment (not as DaemonSet like now) then send data to it, now via "connection" k8satrributes processor the original pod can be discovered and otel can be enriched.

2) ensure that otel data sends k8s.pod.ip or k8s.pod.uid, e.g. by setting env variables for otel instrumentation (See "SDK Configuration"): https://opentelemetry.io/docs/languages/sdk-configuration/general/ and https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter/

To add k8s.pod.ip use the following:
```
env:
 # since otel data is sent to the hostPort on node, the source ip of pod is not visible to otel-collector, so must manually set it as attribute, else k8sattributesprocessor will not enrich
 - name: MY_POD_IP
   valueFrom:
     fieldRef:
       fieldPath: status.podIP
 - name: OTEL_RESOURCE_ATTRIBUTES
   value: k8s.pod.ip=$(MY_POD_IP)
```

Previously this was in otel collector logs (pod connection shown as 10.244.1.1 the cni0 bridge interface on the node):
```
2025-04-17T02:08:50.138Z	debug	k8sattributesprocessor@v0.121.0/processor.go:143	evaluating pod identifier	{"otelcol.component.id": "k8sattributes", "otelcol.component.kind": "Processor", "otelcol.pipeline.id": "metrics", "otelcol.signal": "metrics", "value": [{"Source":{"From":"connection","Name":""},"Value":"10.244.1.1"},{"Source":{"From":"","Name":""},"Value":""},{"Source":{"From":"","Name":""},"Value":""},{"Source":{"From":"","Name":""},"Value":""}]}
2025-04-17T02:08:50.149Z	info	Metrics	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "resource metrics": 1, "metrics": 3, "data points": 7}
2025-04-17T02:08:50.149Z	debug	otlphttpexporter@v0.121.0/otlp.go:177	Preparing to make HTTP request	{"otelcol.component.id": "otlphttp/prometheus", "otelcol.component.kind": "Exporter", "otelcol.signal": "metrics", "url": "http://prometheus-server.prometheus:80/api/v1/otlp/v1/metrics"}
```

After adding pod ip it can locate the pod ("getting the pod") and assign metadata:
```
2025-04-17T02:13:46.287Z	debug	k8sattributesprocessor@v0.121.0/processor.go:143	evaluating pod identifier	{"otelcol.component.id": "k8sattributes", "otelcol.component.kind": "Processor", "otelcol.pipeline.id": "logs", "otelcol.signal": "logs", "value": [{"Source":{"From":"resource_attribute","Name":"k8s.pod.ip"},"Value":"10.244.1.9"},{"Source":{"From":"","Name":""},"Value":""},{"Source":{"From":"","Name":""},"Value":""},{"Source":{"From":"","Name":""},"Value":""}]}
2025-04-17T02:13:46.287Z	debug	k8sattributesprocessor@v0.121.0/processor.go:159	getting the pod	{"otelcol.component.id": "k8sattributes", "otelcol.component.kind": "Processor", "otelcol.pipeline.id": "logs", "otelcol.signal": "logs", "pod": {"Name":"http-server-f55946b57-xncpr","Address":"10.244.1.9","PodUID":"13e5be14-6e18-4df1-976a-4fa7c7da5226","Attributes":{"k8s.deployment.name":"http-server","k8s.namespace.name":"default","k8s.node.name":"worker1","k8s.pod.name":"http-server-f55946b57-xncpr","k8s.pod.start_time":"2025-04-17T02:13:39Z","k8s.pod.uid":"13e5be14-6e18-4df1-976a-4fa7c7da5226"},"StartTime":"2025-04-17T02:13:39Z","Ignore":false,"Namespace":"default","NodeName":"worker1","HostNetwork":false,"Containers":{"ByID":null,"ByName":null},"DeletedAt":"0001-01-01T00:00:00Z"}}
2025-04-17T02:13:46.386Z	info	Logs	{"otelcol.component.id": "debug", "otelcol.component.kind": "Exporter", "otelcol.signal": "logs", "resource logs": 1, "log records": 2}
```

And attributes are visible in prometheus:
![image](https://github.com/user-attachments/assets/dd16ab07-34ec-44f1-9691-4e8710ca88a6)

Job and service name can also be set via service.name env var (duplicates to "job" label as well)

Finally to add e.g. k8s.cluster.uid, must adjust the k8sattributes processor config, enabling an extra k8s.cluster.uid metadata extraction.

Read more about resource attributes that should exist: https://opentelemetry.io/docs/specs/semconv/resource/

The end result is below (latest evolution is the first row to time series):


# View metrics in prometheus

Exported metrics have an instance id which is a UUID identifier "service.instance.id". Read more about it here: https://opentelemetry.io/docs/specs/semconv/attributes-registry/service/#service-instance-id

Note that now labels use a "." dot separated format, so prom queries have to quote them. See: https://prometheus.io/blog/2024/03/14/commitment-to-opentelemetry/#support-utf-8-metric-and-label-names

Links on using otel with prom:
- https://grafana.com/blog/2024/11/06/prometheus-3.0-and-opentelemetry-a-practical-guide-to-storing-and-querying-otel-data/
- UX of using target_info https://docs.google.com/document/d/1gG-eTQ4SxmfbGwkrblnUk97fWQA93umvXHEzQn2Nv7E/edit?tab=t.0
- https://grafana.com/blog/2023/07/20/a-practical-guide-to-data-collection-with-opentelemetry-and-prometheus/#6-use-prometheus-remote-write-exporter
- remote write seems to accept metrics metadata, whereas otel api of prometheus seemengly does not, see: https://github.com/prometheus/prometheus/issues/12608

The following three queries are the same, except last one is forbidden syntax since `__name__` has "." dot in it, so quoted form must be used.
```
{"container.memory.working_set_bytes", "k8s.namespace.name"="kube-system"} / (1024*1024)

{__name__="container.memory.working_set_bytes", "k8s.namespace.name"="kube-system"} / (1024*1024)

container.memory.working_set_bytes{"k8s.namespace.name"="kube-system"} / (1024*1024)
```

![image](https://github.com/user-attachments/assets/e2cfa486-626e-4cb7-9ae4-035bb28ee930)



# Install Opensearch

