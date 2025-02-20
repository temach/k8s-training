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


Partial Output from installing two kafka releases into dev and prod:
```
Upgrading release=kafka, chart=/tmp/helmfile3252012994/prod/kafka/kafka/31.3.1/kafka, namespace=prod
Upgrading release=kafka, chart=/tmp/helmfile3252012994/dev/kafka/kafka/31.3.1/kafka, namespace=dev
Release "kafka" does not exist. Installing it now.
NAME: kafka
LAST DEPLOYED: Thu Feb 20 04:21:52 2025
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
Release "kafka" does not exist. Installing it now.
NAME: kafka
LAST DEPLOYED: Thu Feb 20 04:21:52 2025
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
kafka	prod     	1       	2025-02-20 04:21:52.262180787 +0000 UTC	deployed	kafka-31.3.1	3.9.0      

kafka	dev      	1       	2025-02-20 04:21:52.266007802 +0000 UTC	deployed	kafka-31.3.1	3.9.0      


UPDATED RELEASES:
NAME    NAMESPACE   CHART           VERSION   DURATION
kafka   prod        bitnami/kafka   31.3.1          3s
kafka   dev         bitnami/kafka   31.3.1          3s
```


# Fix pods

Kafka does not start because it uses PVC, expects volumes. 
For prod deployment set broker/controller "persistense.enabled: false"

For dev deployment create local pv as bellow:

Keep in mind:
- helm/helmfile does not delete PVC (the claims) of statefullsets (which is kafka) by default, must manually delete them

Current status:
```
# kubectl get pods -A 
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE
dev            kafka-broker-0                   0/1     Pending   0               13m
dev            kafka-controller-0               0/1     Pending   0               13m
dev            kafka-controller-1               0/1     Pending   0               13m
dev            kafka-controller-2               0/1     Pending   0               13m
kube-flannel   kube-flannel-ds-b5gvw            1/1     Running   4 (5m3s ago)    23d
kube-flannel   kube-flannel-ds-lxtzt            1/1     Running   4 (5m9s ago)    23d
kube-flannel   kube-flannel-ds-vklr7            1/1     Running   4 (6h46m ago)   23d
kube-flannel   kube-flannel-ds-wjmtv            1/1     Running   3 (5m3s ago)    23d
kube-system    coredns-7c65d6cfc9-42bps         1/1     Running   2 (6m ago)      23d
kube-system    coredns-7c65d6cfc9-d94dc         1/1     Running   2 (5m59s ago)   23d
kube-system    etcd-master                      1/1     Running   2 (6h46m ago)   23d
kube-system    kube-apiserver-master            1/1     Running   2 (6h46m ago)   23d
kube-system    kube-controller-manager-master   1/1     Running   2 (6h46m ago)   23d
kube-system    kube-proxy-6k7fg                 1/1     Running   2 (6h46m ago)   23d
kube-system    kube-proxy-77njz                 1/1     Running   2 (6m3s ago)    23d
kube-system    kube-proxy-d2nmb                 1/1     Running   2 (6m ago)      23d
kube-system    kube-proxy-std4j                 1/1     Running   2 (5m59s ago)   23d
kube-system    kube-scheduler-master            1/1     Running   2 (6h46m ago)   23d
prod           kafka-broker-0                   0/1     Pending   0               13m
prod           kafka-broker-1                   0/1     Pending   0               13m
prod           kafka-broker-2                   0/1     Pending   0               13m
prod           kafka-broker-3                   0/1     Pending   0               13m
prod           kafka-broker-4                   0/1     Pending   0               13m
prod           kafka-controller-0               0/1     Pending   0               13m
prod           kafka-controller-1               0/1     Pending   0               13m
prod           kafka-controller-2               0/1     Pending   0               13m


# kubectl get events -A --watch

prod           3m4s        Warning   FailedScheduling          pod/kafka-controller-0                          0/4 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

Check out example PVC:
```
# kubectl get -n dev pvc -o yaml data-kafka-broker-0 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  creationTimestamp: "2025-02-19T13:35:54Z"
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app.kubernetes.io/component: broker
    app.kubernetes.io/instance: kafka
    app.kubernetes.io/name: kafka
    app.kubernetes.io/part-of: kafka
  name: data-kafka-broker-0
  namespace: dev
  resourceVersion: "95236"
  uid: b8f7e583-db50-4891-834d-d8789017f4cb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  volumeMode: Filesystem
status:
  phase: Pending
```


And their sizes:
```
root@master:~# kubectl get pvc --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,SIZE:.spec.resources.requests.storage"
NAMESPACE   NAME                      STATUS    SIZE
dev         data-kafka-broker-0       Pending   5Gi
dev         data-kafka-controller-0   Pending   3Gi
dev         data-kafka-controller-1   Pending   3Gi
dev         data-kafka-controller-2   Pending   3Gi
```

Total available disks for local storage are ~24GB free per node * 3 ~= 72GB total.


Lets create a storageclass and multiple "local" pv to satisfy each pvc.
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner # indicates that this StorageClass does not support automatic provisioning
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: worker1-pv1
spec:
  capacity:
    storage: 6Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    # full path to storage volume on node
    path: /opt/my-local-storage/worker1-pv1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: worker1-pv2
spec:
  capacity:
    storage: 4Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    # full path to storage volume on node
    path: /opt/my-local-storage/worker1-pv2
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: worker3-pv6
spec:
  capacity:
    storage: 4Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    # full path to storage volume on node
    path: /opt/my-local-storage/worker3-pv6
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker3
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: worker3-pv7
spec:
  capacity:
    storage: 4Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    # full path to storage volume on node
    path: /opt/my-local-storage/worker3-pv7
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker3
```


Then applying just the storageclass and the first volume:
```
root@master:~# kubectl apply -f pv.yaml 
storageclass.storage.k8s.io/local-storage created
persistentvolume/worker1-pv1 created

root@master:~# kubectl get pv -A -o wide
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                         STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE   VOLUMEMODE
worker1-pv1   6Gi        RWO            Delete           Bound    dev/data-kafka-controller-0   local-storage   <unset>                          16s   Filesystem

root@master:~# kubectl get pvc -A -o wide
NAMESPACE   NAME                      STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE   VOLUMEMODE
dev         data-kafka-broker-0       Pending                                           local-storage   <unset>                 11m   Filesystem
dev         data-kafka-controller-0   Bound     worker1-pv1   6Gi        RWO            local-storage   <unset>                 11m   Filesystem
dev         data-kafka-controller-1   Pending                                           local-storage   <unset>                 11m   Filesystem
dev         data-kafka-controller-2   Pending                                           local-storage   <unset>                 11m   Filesystem

root@master:~# kubectl get pods -A
NAMESPACE      NAME                             READY   STATUS     RESTARTS       AGE
dev            kafka-broker-0                   0/1     Pending    0              11m
dev            kafka-controller-0               0/1     Init:0/1   0              11m
dev            kafka-controller-1               0/1     Pending    0              11m
dev            kafka-controller-2               0/1     Pending    0              11m
kube-flannel   kube-flannel-ds-b5gvw            1/1     Running    6 (130m ago)   24d
kube-flannel   kube-flannel-ds-lxtzt            1/1     Running    6 (43m ago)    24d
kube-flannel   kube-flannel-ds-vklr7            1/1     Running    6 (170m ago)   24d
kube-flannel   kube-flannel-ds-wjmtv            1/1     Running    5 (43m ago)    24d
kube-system    coredns-7c65d6cfc9-d94dc         1/1     Running    3              24d
kube-system    coredns-7c65d6cfc9-zc2sr         1/1     Running    0              126m
kube-system    etcd-master                      1/1     Running    3 (171m ago)   24d
kube-system    kube-apiserver-master            1/1     Running    3 (171m ago)   24d
kube-system    kube-controller-manager-master   1/1     Running    3 (171m ago)   24d
kube-system    kube-proxy-6k7fg                 1/1     Running    3 (171m ago)   24d
kube-system    kube-proxy-77njz                 1/1     Running    3 (44m ago)    24d
kube-system    kube-proxy-d2nmb                 1/1     Running    3 (44m ago)    24d
kube-system    kube-proxy-std4j                 1/1     Running    3 (12h ago)    24d
kube-system    kube-scheduler-master            1/1     Running    3 (171m ago)   24d
prod           kafka-broker-0                   1/1     Running    0              11m
prod           kafka-broker-1                   1/1     Running    0              11m
prod           kafka-broker-2                   1/1     Running    0              11m
prod           kafka-broker-3                   1/1     Running    0              11m
prod           kafka-broker-4                   1/1     Running    0              11m
prod           kafka-controller-0               1/1     Running    0              11m
prod           kafka-controller-1               1/1     Running    0              11m
prod           kafka-controller-2               1/1     Running    0              11m
```


However path must be created beforehand for each volume else (mkdir -p /opt/my-local-storage/worker1-pv1 and kill pod is enough):
```
  Warning  FailedMount       52s (x8 over 116s)  kubelet            MountVolume.NewMounter initialization failed for volume "worker1-pv1" : path "/opt/my-local-storage/worker1-pv1" does not exist
```

After all pv are provisioned, if they do not match the same nodes with pods, the pods are not moved. Must kill pods to re-trigger scheduling:
```
root@master:~# kubectl get pvc -A
NAMESPACE   NAME                      STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
dev         data-kafka-broker-0       Pending                                           local-storage   <unset>                 20m
dev         data-kafka-controller-0   Bound     worker1-pv1   6Gi        RWO            local-storage   <unset>                 20m
dev         data-kafka-controller-1   Pending                                           local-storage   <unset>                 20m
dev         data-kafka-controller-2   Pending                                           local-storage   <unset>                 20m

root@master:~# kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                         STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE
worker1-pv1   6Gi        RWO            Delete           Bound       dev/data-kafka-controller-0   local-storage   <unset>                          9m49s
worker1-pv2   4Gi        RWO            Delete           Available                                 local-storage   <unset>                          3m46s
worker3-pv6   4Gi        RWO            Delete           Available                                 local-storage   <unset>                          14s
worker3-pv7   4Gi        RWO            Delete           Available                                 local-storage   <unset>                          14s
```

Also faced an issue - not enougth cpu for two kafka clusters. So uninstalled prod, and now running just dev:
```
root@master:~# kubectl get pvc -A -o wide
NAMESPACE   NAME                      STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE   VOLUMEMODE
dev         data-kafka-broker-0       Bound    worker1-pv1   6Gi        RWO            local-storage   <unset>                 17s   Filesystem
dev         data-kafka-controller-0   Bound    worker3-pv6   4Gi        RWO            local-storage   <unset>                 17s   Filesystem
dev         data-kafka-controller-1   Bound    worker1-pv2   4Gi        RWO            local-storage   <unset>                 17s   Filesystem
dev         data-kafka-controller-2   Bound    worker3-pv7   4Gi        RWO            local-storage   <unset>                 17s   Filesystem

root@master:~# kubectl get pv -o wide
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                         STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE   VOLUMEMODE
worker1-pv1   6Gi        RWO            Delete           Bound    dev/data-kafka-broker-0       local-storage   <unset>                          34m   Filesystem
worker1-pv2   4Gi        RWO            Delete           Bound    dev/data-kafka-controller-1   local-storage   <unset>                          28m   Filesystem
worker3-pv6   4Gi        RWO            Delete           Bound    dev/data-kafka-controller-0   local-storage   <unset>                          24m   Filesystem
worker3-pv7   4Gi        RWO            Delete           Bound    dev/data-kafka-controller-2   local-storage   <unset>                          24m   Filesystem


root@master:~# kubectl get pods -A -o wide
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE    IP            NODE      NOMINATED NODE   READINESS GATES
dev            kafka-broker-0                   1/1     Running   0               104s   10.244.1.13   worker1   <none>           <none>
dev            kafka-controller-0               1/1     Running   0               104s   10.244.2.12   worker3   <none>           <none>
dev            kafka-controller-1               1/1     Running   0               104s   10.244.1.14   worker1   <none>           <none>
dev            kafka-controller-2               1/1     Running   0               104s   10.244.2.11   worker3   <none>           <none>
kube-flannel   kube-flannel-ds-b5gvw            1/1     Running   6 (165m ago)    24d    10.128.0.25   worker1   <none>           <none>
kube-flannel   kube-flannel-ds-lxtzt            1/1     Running   6 (78m ago)     24d    10.128.0.3    worker3   <none>           <none>
kube-flannel   kube-flannel-ds-vklr7            1/1     Running   6 (3h25m ago)   24d    10.128.0.16   master    <none>           <none>
kube-flannel   kube-flannel-ds-wjmtv            1/1     Running   5 (79m ago)     24d    10.128.0.26   worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-d94dc         1/1     Running   3               24d    10.244.1.5    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-zc2sr         1/1     Running   0               161m   10.244.0.6    master    <none>           <none>
kube-system    etcd-master                      1/1     Running   3 (3h26m ago)   24d    10.128.0.16   master    <none>           <none>
kube-system    kube-apiserver-master            1/1     Running   3 (3h26m ago)   24d    10.128.0.16   master    <none>           <none>
kube-system    kube-controller-manager-master   1/1     Running   3 (3h26m ago)   24d    10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-6k7fg                 1/1     Running   3 (3h26m ago)   24d    10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-77njz                 1/1     Running   3 (79m ago)     24d    10.128.0.3    worker3   <none>           <none>
kube-system    kube-proxy-d2nmb                 1/1     Running   3 (79m ago)     24d    10.128.0.26   worker2   <none>           <none>
kube-system    kube-proxy-std4j                 1/1     Running   3 (13h ago)     24d    10.128.0.25   worker1   <none>           <none>
kube-system    kube-scheduler-master            1/1     Running   3 (3h26m ago)   24d    10.128.0.16   master    <none>           <none>
````


When recreating volumes, had to manually remove claimRef in pv. Also manually clean /opt/my-local-storage/worker1-pv*/ directories to empty volumes.
