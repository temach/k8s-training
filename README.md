# k8s-training


# Install helmfile

On debian master node: download release from https://github.com/helmfile/helmfile/releases
```
# sudo su
# wget 'https://github.com/helmfile/helmfile/releases/download/v1.0.0-rc.10/helmfile_1.0.0-rc.10_linux_amd64.tar.gz'
# apt update && apt install unp
# unp helmfile_1.0.0-rc.10_linux_amd64.tar.gz
# chown root:root ./helmfile
# mv ./helmfile /usr/local/bin/
```


Install plugins:
```
# helmfile init

The helm plugin "diff" is not installed, do you want to install it? [y/n]: y
Install helm plugin diff
Downloading https://github.com/databus23/helm-diff/releases/download/v3.9.14/helm-diff-linux-amd64.tgz
Preparing to install into /root/.local/share/helm/plugins/helm-diff
Installed plugin: diff

The helm plugin "secrets" is not installed, do you want to install it? [y/n]: y
Install helm plugin secrets
Installed plugin: secrets

The helm plugin "s3" is not installed, do you want to install it? [y/n]: y
Install helm plugin s3
Downloading and installing helm-s3 v0.16.0 ...
Checksum is valid.
Installed plugin: s3

The helm plugin "helm-git" is not installed, do you want to install it? [y/n]: y
Install helm plugin helm-git
Installed plugin: helm-git

helmfile initialization completed!
```

# helmfile.yaml problems

- must use oci registry

- must specify exact chart version, can not use "latest" chart version, else error: 
```
in ./helmfile.yaml: [release "kafka": the version for OCI charts should be semver compliant, the latest tag is not supported anymore for helm >= 3.8.0]
```
To find latest version is 31.3.1 do:
```
# helm pull oci://registry-1.docker.io/bitnamicharts/kafka
Pulled: registry-1.docker.io/bitnamicharts/kafka:31.3.1
Digest: sha256:9af9ffc5424b9fcfe50d24d3d4ad7eceeee763632dfd30415060ee1b79155124
```



# Install
Create /root/helmfile.yaml and install:
```
# export KUBECONFIG=/etc/kubernetes/admin.conf
# helmfile apply
```


Partial Output:
```
Upgrading release=kafka, chart=/tmp/helmfile713633676/dev/kafka/kafka/31.3.1/kafka, namespace=dev
Upgrading release=kafka, chart=/tmp/helmfile713633676/prod/kafka/kafka/31.3.1/kafka, namespace=prod
Release "kafka" does not exist. Installing it now.
NAME: kafka
LAST DEPLOYED: Wed Feb 19 13:35:52 2025
NAMESPACE: dev
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: kafka
CHART VERSION: 31.3.1
APP VERSION: 3.9.0

Did you know there are enterprise versions of the Bitnami catalog? For enhanced secure software supply chain features, unlimited pulls from Docker, LTS support, or application customization, see Bitnami Premium or Tanzu Application Catalog. See https://www.arrow.com/globalecs/na/vendors/bitnami for more information.

** Please be patient while the chart is being deployed **

Kafka can be accessed by consumers via port 9092 on the following DNS name from within your cluster:

    kafka.dev.svc.cluster.local

Each Kafka broker can be accessed by producers via port 9092 on the following DNS name(s) from within your cluster:

    kafka-controller-0.kafka-controller-headless.dev.svc.cluster.local:9092
    kafka-controller-1.kafka-controller-headless.dev.svc.cluster.local:9092
    kafka-controller-2.kafka-controller-headless.dev.svc.cluster.local:9092
    kafka-broker-0.kafka-broker-headless.dev.svc.cluster.local:9092

To create a pod that you can use as a Kafka client run the following commands:

    kubectl run kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.9.0-debian-12-r6 --namespace dev --command -- sleep infinity
    kubectl exec --tty -i kafka-client --namespace dev -- bash

    PRODUCER:
        kafka-console-producer.sh \
            --bootstrap-server kafka.dev.svc.cluster.local:9092 \
            --topic test

    CONSUMER:
        kafka-console-consumer.sh \
            --bootstrap-server kafka.dev.svc.cluster.local:9092 \
            --topic test \
            --from-beginning

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
  - broker.resources
  - controller.resources
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

Listing releases matching ^kafka$
kafka	dev      	1       	2025-02-19 13:35:52.865763999 +0000 UTC	deployed	kafka-31.3.1	3.9.0      

Release "kafka" does not exist. Installing it now.
NAME: kafka
LAST DEPLOYED: Wed Feb 19 13:35:52 2025
NAMESPACE: prod
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: kafka
CHART VERSION: 31.3.1
APP VERSION: 3.9.0

Did you know there are enterprise versions of the Bitnami catalog? For enhanced secure software supply chain features, unlimited pulls from Docker, LTS support, or application customization, see Bitnami Premium or Tanzu Application Catalog. See https://www.arrow.com/globalecs/na/vendors/bitnami for more information.

** Please be patient while the chart is being deployed **

Kafka can be accessed by consumers via port 9092 on the following DNS name from within your cluster:

    kafka.prod.svc.cluster.local

Each Kafka broker can be accessed by producers via port 9092 on the following DNS name(s) from within your cluster:

    kafka-controller-0.kafka-controller-headless.prod.svc.cluster.local:9092
    kafka-controller-1.kafka-controller-headless.prod.svc.cluster.local:9092
    kafka-controller-2.kafka-controller-headless.prod.svc.cluster.local:9092
    kafka-broker-0.kafka-broker-headless.prod.svc.cluster.local:9092
    kafka-broker-1.kafka-broker-headless.prod.svc.cluster.local:9092
    kafka-broker-2.kafka-broker-headless.prod.svc.cluster.local:9092
    kafka-broker-3.kafka-broker-headless.prod.svc.cluster.local:9092
    kafka-broker-4.kafka-broker-headless.prod.svc.cluster.local:9092

The CLIENT listener for Kafka client connections from within your cluster have been configured with the following security settings:
    - SASL authentication

To connect a client to your Kafka, you need to create the 'client.properties' configuration files with the content below:

security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
    username="user1" \
    password="$(kubectl get secret kafka-user-passwords --namespace prod -o jsonpath='{.data.client-passwords}' | base64 -d | cut -d , -f 1)";

To create a pod that you can use as a Kafka client run the following commands:

    kubectl run kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.5.2 --namespace prod --command -- sleep infinity
    kubectl cp --namespace prod /path/to/client.properties kafka-client:/tmp/client.properties
    kubectl exec --tty -i kafka-client --namespace prod -- bash

    PRODUCER:
        kafka-console-producer.sh \
            --producer.config /tmp/client.properties \
            --bootstrap-server kafka.prod.svc.cluster.local:9092 \
            --topic test

    CONSUMER:
        kafka-console-consumer.sh \
            --consumer.config /tmp/client.properties \
            --bootstrap-server kafka.prod.svc.cluster.local:9092 \
            --topic test \
            --from-beginning
WARNING: Rolling tag detected (bitnami/kafka:3.5.2), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
  - broker.resources
  - controller.resources
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

⚠ SECURITY WARNING: Original containers have been substituted. This Helm chart was designed, tested, and validated on multiple platforms using a specific set of Bitnami and Tanzu Application Catalog containers. Substituting other containers is likely to cause degraded security and performance, broken chart features, and missing environment variables.

Substituted images detected:
  - docker.io/bitnami/kafka:3.5.2

⚠ WARNING: Original containers have been retagged. Please note this Helm chart was tested, and validated on multiple platforms using a specific set of Tanzu Application Catalog containers. Substituting original image tags could cause unexpected behavior.

Retagged images:
  - docker.io/bitnami/kafka:3.5.2

Listing releases matching ^kafka$
kafka	prod     	1       	2025-02-19 13:35:52.932056019 +0000 UTC	deployed	kafka-31.3.1	3.9.0      


UPDATED RELEASES:
NAME    NAMESPACE   CHART           VERSION   DURATION
kafka   dev         bitnami/kafka   31.3.1          2s
kafka   prod        bitnami/kafka   31.3.1          2s
```


