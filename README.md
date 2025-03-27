# Install monitoring stack

See https://opentelemetry.io/ecosystem/vendors/ for projects that support OpenTelemetry.

Demo helm chart that installs components: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo
and docs for the helm chart: https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/

A good choice: Jaeger, FluentBit + Opensearch, Prometheus, Grafana


### Install OpenTelemetry Collector

Github repo: https://github.com/open-telemetry/opentelemetry-collector

Helm charts: https://opentelemetry.io/docs/platforms/kubernetes/helm/

Different flavours of collector: https://github.com/open-telemetry/opentelemetry-collector-releases
- The fat flavour with everything is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib
- The flavour for k8s is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-k8s
- The super-minimalist flavour is https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-otlp


```
# helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
# helm repo


```
