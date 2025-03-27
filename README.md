# Install monitoring stack

See https://opentelemetry.io/ecosystem/vendors/ for projects that support OpenTelemetry.

Demo helm chart that installs components: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo
and docs for the helm chart: https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/

A good choice: Jaeger, FluentBit + Opensearch, Prometheus, Grafana

Registry of library/app integrations with Otel: https://opentelemetry.io/ecosystem/registry/?s=apache


### Install Prometheus

Take helmfile from kubernetes-istio branch, it has already been done.


### Install OpenTelemetry Collector

Strictly speaking collector is not necessary, metrics/logs/traces can be send directly to the backend,
but collector is nice and it can aggreagate logs (like fluentd).

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
```
