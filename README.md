# Examine constraints: Node/Pod Affinity/Anti-Affinity, TopologySpreadConstraints

### Node/Pod Affinity/Anti-Affinity, 

Pod affinity details: https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/podaffinity.md 

Deploy with 3 replicas and no constraints:
```
$ kubectl apply -f deployment.yaml 
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE    IP             NODE      NOMINATED NODE   READINESS GATES
http-server-54766f9fdc-622zt   1/1     Running   0          110s   10.244.3.15    worker3   <none>           <none>
http-server-54766f9fdc-nv66x   1/1     Running   0          20m    10.244.1.136   worker1   <none>           <none>
http-server-54766f9fdc-x2vsm   1/1     Running   0          110s   10.244.2.38    worker2   <none>           <none>
```

Master node has control-plan:NoSchedule taint, so its not used:
```
$ k describe node master
Name:               master
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=master
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        flannel.alpha.coreos.com/backend-data: {"VNI":1,"VtepMAC":"4a:cc:c9:15:81:3f"}
                    flannel.alpha.coreos.com/backend-type: vxlan
                    flannel.alpha.coreos.com/kube-subnet-manager: true
                    flannel.alpha.coreos.com/public-ip: 10.128.0.16
                    kubeadm.alpha.kubernetes.io/cri-socket: unix:///var/run/cri-dockerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 26 Jan 2025 12:24:02 +0500
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Unschedulable:      false
....
```


Add nodeAffinity to worker1 and worker3, redeploy:
```
$ cat deployment.yaml
kind: Deployment
spec:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - worker1
                - worker3

$ k apply -f deployment.yaml 
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE     IP             NODE      NOMINATED NODE   READINESS GATES
http-server-54766f9fdc-622zt   1/1     Terminating   0          5m59s   10.244.3.15    worker3   <none>           <none>
http-server-54766f9fdc-nv66x   1/1     Terminating   0          24m     10.244.1.136   worker1   <none>           <none>
http-server-54766f9fdc-x2vsm   1/1     Terminating   0          5m59s   10.244.2.38    worker2   <none>           <none>
http-server-7cdd7fcb64-pm5zg   1/1     Running       0          9s      10.244.3.16    worker3   <none>           <none>
http-server-7cdd7fcb64-bz69c   1/1     Running       0          12s     10.244.1.137   worker1   <none>           <none>
http-server-7cdd7fcb64-lfr88   1/1     Running       0          6s      10.244.1.138   worker1   <none>           <none>
```

Add podAnti-Affinity and set 2 replicas:
```
$ cat deployment.yaml
kind: Deployment
spec:
  replicas: 2
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - http-server
              topologyKey: kubernetes.io/hostname

$ k apply -f deployment.yaml 
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE     IP             NODE      NOMINATED NODE   READINESS GATES
http-server-5b5f8cd7f7-4ph7s   1/1     Running       0          5s      10.244.1.139   worker1   <none>           <none>
http-server-5b5f8cd7f7-dhdlv   1/1     Running       0          8s      10.244.3.17    worker3   <none>           <none>
http-server-7cdd7fcb64-bz69c   1/1     Terminating   0          8m49s   10.244.1.137   worker1   <none>           <none>
http-server-7cdd7fcb64-lfr88   1/1     Terminating   0          8m43s   10.244.1.138   worker1   <none>           <none>
http-server-7cdd7fcb64-pm5zg   1/1     Terminating   0          8m46s   10.244.3.16    worker3   <none>           <none>
```

### TopologySpreadConstraints

Explanation see: https://github.com/kubernetes/enhancements/blob/f3fa3a12d303a6b749efd072987a39aab159f9d5/keps/sig-scheduling/895-pod-topology-spread/README.md 

Add topologySpreadConstraints:
```
$ cat deployment.yaml
kind: Deployment
spec:
  replicas: 5
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: http-server


$ k apply -f deployment.yaml
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
http-server-5c89767bb4-526rm   1/1     Running       0          13s   10.244.3.36    worker3   <none>           <none>
http-server-5c89767bb4-j6n26   1/1     Running       0          13s   10.244.1.159   worker1   <none>           <none>
http-server-5c89767bb4-qsz4s   1/1     Running       0          15s   10.244.1.158   worker1   <none>           <none>
http-server-5c89767bb4-th664   1/1     Running       0          15s   10.244.3.34    worker3   <none>           <none>
http-server-5c89767bb4-vc7wd   1/1     Running       0          15s   10.244.3.35    worker3   <none>           <none>
```

Now change Anti-Affinity to Affinity and but keep topology constraints:
```
$ cat deployment.yaml
kind: Deployment
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 4
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: http-server
      affinity:
        podAffinity:
        # see: https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/podaffinity.md
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 30
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - http-server


$ k apply -f deployment.yaml
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE    IP             NODE      NOMINATED NODE   READINESS GATES
http-server-66fbf8d895-5kkpw   1/1     Running       0          19s    10.244.1.165   worker1   <none>           <none>
http-server-66fbf8d895-5lsbp   1/1     Running       0          15s    10.244.1.167   worker1   <none>           <none>
http-server-66fbf8d895-ms95z   1/1     Running       0          15s    10.244.1.168   worker1   <none>           <none>
http-server-66fbf8d895-vzc65   1/1     Running       0          16s    10.244.1.166   worker1   <none>           <none>
http-server-66fbf8d895-kv2td   1/1     Running       0          18s    10.244.3.38    worker3   <none>           <none>
http-server-66fbf8d895-qhtrq   1/1     Running       0          19s    10.244.3.37    worker3   <none>           <none>
```

This way pods are spread but allowing to have a differnce of up to 4 pods between each topology (each hostname makes a separate topology in this case)



### Taints and Tolerations

Apply taint to worker3 and trigger re-deploy:
```
$ k taint nodes worker3 no-static-ip.example.org=true:NoSchedule  
node/worker3 tainted

$ k rollout restart deployment/http-server

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
http-server-5c5c4b6d6-296bj    0/1     Pending       0          12s   <none>         <none>    <none>           <none>
http-server-5c5c4b6d6-54z42    1/1     Running       0          16s   10.244.1.171   worker1   <none>           <none>
http-server-5c5c4b6d6-j68zn    1/1     Running       0          13s   10.244.1.173   worker1   <none>           <none>
http-server-5c5c4b6d6-q6sfj    1/1     Running       0          16s   10.244.1.170   worker1   <none>           <none>
http-server-5c5c4b6d6-r4tc2    1/1     Running       0          12s   10.244.1.172   worker1   <none>           <none>
http-server-5c5c4b6d6-tt9mg    1/1     Running       0          16s   10.244.1.169   worker1   <none>           <none>
```

Add toleration to the taint into deployment and re-deploy:
```
$ k apply -f deployment.yaml
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS        RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
http-server-75d5d6c78c-5ssd5   1/1     Running       0          19s   10.244.1.177   worker1   <none>           <none>
http-server-75d5d6c78c-6km87   1/1     Running       0          20s   10.244.1.175   worker1   <none>           <none>
http-server-75d5d6c78c-krfrc   1/1     Running       0          22s   10.244.1.174   worker1   <none>           <none>
http-server-75d5d6c78c-kw6m6   1/1     Running       0          19s   10.244.1.176   worker1   <none>           <none>
http-server-75d5d6c78c-t2hjb   1/1     Running       0          22s   10.244.3.40    worker3   <none>           <none>
http-server-75d5d6c78c-t9tqx   1/1     Running       0          22s   10.244.3.39    worker3   <none>           <none>

$ k describe node worker3
Name:               worker3
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=worker3
                    kubernetes.io/os=linux
Annotations:        flannel.alpha.coreos.com/backend-data: {"VNI":1,"VtepMAC":"ce:50:66:c8:a3:ab"}
                    flannel.alpha.coreos.com/backend-type: vxlan
                    flannel.alpha.coreos.com/kube-subnet-manager: true
                    flannel.alpha.coreos.com/public-ip: 10.128.0.3
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sun, 16 Mar 2025 22:54:24 +0500
Taints:             no-static-ip.example.org=true:NoSchedule
Unschedulable:      false
....
```



# Extra: Add custom kube scheduler configuration file that favours ImageLocallity

### View current kube-scheduler configuration


View current options of kube-scheduler:
```
# ps auxf | grep kube-scheduler
root        1326  0.6  0.9 1292572 73884 ?       Ssl  09:43   0:54  \_ kube-scheduler --authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true
```

/etc/kubernetes/scheduler.conf only holds connection parameters to the cluster (e.g. it is a kubeconfig type of file)
Actual scheduler configuration is found in /etc/kubernetes/manifests/kube-scheduler.yaml:
```
# cat /etc/kubernetes/manifests/kube-scheduler.yaml 

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.k8s.io/kube-scheduler:v1.32.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-scheduler
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 10259
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```


### Add KubeSchedulerConfiguration via kubeadm-config.yaml

To install it must modify file on the filesystem, can not change scheduler config via kubectl.
see: https://kubernetes.io/docs/reference/scheduling/config/
```
You can customize the behavior of the kube-scheduler by writing a configuration file and passing its path as a command line argument.
```

Because cluster is created with kubeadm, add the options to kubeadm-config.yaml under ClusterConfiguration.scheduler.
kubeadm spec see: https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
and also: https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta4

```
# cat /root/kubeadm-config.yaml 

apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
localAPIEndpoint:
  advertiseAddress: 10.128.0.16
  name: master

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.31.0
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr apparently special value for flannel
  serviceSubnet: "10.255.0.0/16"

scheduler:
  extraArgs:
    - name: config
      value: "/etc/kubernetes/kube-scheduler-custom.conf"
  extraVolumes:
    - name: "kube-scheduler-custom-conf"
      hostPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      mountPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      readOnly: true
      pathType: File

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
```

Check that kubeadm config in-cluster matches the file on filesystem:

```
# kubectl get configmap -n kube-system kubeadm-config -o yaml
apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer: {}
    apiVersion: kubeadm.k8s.io/v1beta4
    caCertificateValidityPeriod: 87600h0m0s
    certificateValidityPeriod: 8760h0m0s
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controllerManager: {}
    dns: {}
    encryptionAlgorithm: RSA-2048
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: registry.k8s.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.32.1
    networking:
      dnsDomain: cluster.local
      podSubnet: 10.244.0.0/16
      serviceSubnet: 10.255.0.0/16
    proxy: {}
    scheduler: {}
kind: ConfigMap
metadata:
  creationTimestamp: "2025-01-26T07:24:04Z"
  name: kubeadm-config
  namespace: kube-system
  resourceVersion: "26566"
  uid: 5da108b1-0d4e-4af8-bdb1-e18c98505685
```

Note that cluster version needs to be updated in the filesystem config v1.31.0 -> v1.32.1, appart from that everything matches.
Also note that localApiEndpoint lost .name property.


### Final config files

Final kubeadm-conf.yaml
```
# cat /root/kubeadm-config.yaml 

apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
localAPIEndpoint:
  advertiseAddress: 10.128.0.16

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v1.32.1
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr apparently special value for flannel
  serviceSubnet: "10.255.0.0/16"

scheduler:
  extraArgs:
    - name: config
      value: "/etc/kubernetes/kube-scheduler-custom.conf"
  extraVolumes:
    - name: "kube-scheduler-custom-conf"
      hostPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      mountPath: "/etc/kubernetes/kube-scheduler-custom.conf"
      readOnly: true
      pathType: File

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
```


And final /etc/kubernetes/kube-scheduler-custom.conf, see: https://kubernetes.io/docs/reference/scheduling/config/

```
# cat /etc/kubernetes/kube-scheduler-custom.conf

apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: /etc/kubernetes/scheduler.conf
leaderElection:
  leaderElect: true
profiles:
  - schedulerName: default-scheduler
  - schedulerName: image-locality-scheduler
    plugins:
      score:
        enabled:
          - name: ImageLocality
            weight: 100
```


### Apply changed kubeadm config to reconfigure cluster

see: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/

Its possible to manually edit /etc/kubernetes/manifests which will re-create static the pod, but for IaC use kubeadm:

```
# kubeadm init phase control-plane scheduler --config /root/kubeadm-config.yaml
```

Note that I did NOT manually edit the kubeadm-config ConfigMap, only ran the init phase command.


At this point I forgot to create kube-scheduler-custom.conf, and got error on kube-scheduler-master pod:
```
 kubelet  MountVolume.SetUp failed for volume "kube-scheduler-custom-conf" : hostPath type check failed: /etc/kubernetes/kube-scheduler-custom.conf is not a file
```

After creating the file and manual restart of scheduler, all is working:
```
# kubectl delete pod -n kube-system kube-scheduler-master
```

Verify that scheduler uses new config file:
```
# ps axuf | grep scheduler
root       18578  0.7  0.8 1292572 68704 ?       Ssl  20:58   0:12  \_ kube-scheduler --authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --config=/etc/kubernetes/kube-scheduler-custom.conf --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true

# cat /etc/kubernetes/manifests/kube-scheduler.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --config=/etc/kubernetes/kube-scheduler-custom.conf
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.k8s.io/kube-scheduler:v1.32.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-scheduler
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 10259
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/kube-scheduler-custom.conf
      name: kube-scheduler-custom-conf
      readOnly: true
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/kube-scheduler-custom.conf
      type: File
    name: kube-scheduler-custom-conf
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```

Deploy a pod using the new scheduler:
```
$ cat deployment.yaml
kind: Deployment
spec:
  template:
    spec:
      schedulerName: image-locality-scheduler


$ k get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
http-server-66fbf8d895-5kkpw   1/1     Running   0          12m   10.244.1.165   worker1   <none>           <none>
http-server-66fbf8d895-5lsbp   1/1     Running   0          12m   10.244.1.167   worker1   <none>           <none>
http-server-66fbf8d895-kv2td   1/1     Running   0          12m   10.244.3.38    worker3   <none>           <none>
http-server-66fbf8d895-ms95z   1/1     Running   0          12m   10.244.1.168   worker1   <none>           <none>
http-server-66fbf8d895-qhtrq   1/1     Running   0          12m   10.244.3.37    worker3   <none>           <none>
http-server-66fbf8d895-vzc65   1/1     Running   0          12m   10.244.1.166   worker1   <none>           <none>

$ k apply -f deployment.yaml 
service/http-server unchanged
deployment.apps/http-server configured

$ k get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE    IP             NODE      NOMINATED NODE   READINESS GATES
http-server-756f76f767-2gvbd   1/1     Running   0          105s   10.244.3.41    worker3   <none>           <none>
http-server-756f76f767-6nktl   1/1     Running   0          109s   10.244.1.179   worker1   <none>           <none>
http-server-756f76f767-kvhvg   1/1     Running   0          106s   10.244.1.181   worker1   <none>           <none>
http-server-756f76f767-n8tjl   1/1     Running   0          106s   10.244.1.182   worker1   <none>           <none>
http-server-756f76f767-nhl4s   1/1     Running   0          109s   10.244.1.178   worker1   <none>           <none>
http-server-756f76f767-v9zzk   1/1     Running   0          109s   10.244.1.180   worker1   <none>           <none>
```

Not much of an effect since both nodes previously ran the same image and have it in cache already. 
Delete deployment, clear worker1 image cache, and deploy again.
```
$ k scale deployment http-server --replicas=0
deployment.apps/http-server scaled

$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1

root@worker1:~# docker image ls
REPOSITORY                                               TAG                                        IMAGE ID       CREATED         SIZE
quay.io/kiali/kiali                                      v2.7.0                                     457e7fe129db   7 days ago      145MB
ghcr.io/aaronpowell/httpstatus                           155dc50c6959df1db12cc0e07da3f2e0035a1426   8906b7087b62   13 days ago     227MB
istio/proxyv2                                            1.25.0                                     61b765c3bb18   3 weeks ago     285MB
quay.io/prometheus/prometheus                            v3.2.1                                     503e04849f1c   3 weeks ago     295MB
quay.io/prometheus-operator/prometheus-config-reloader   v0.80.1                                    14baaf2cf785   4 weeks ago     43.5MB
quay.io/prometheus/node-exporter                         v1.9.0                                     aaa0ee0c2359   5 weeks ago     25MB
python                                                   3.13                                       36d17f72f4f3   6 weeks ago     1.02GB
bitnami/kafka                                            3.9.0-debian-12-r6                         c666ee6c3d0e   7 weeks ago     446MB
registry.k8s.io/kube-proxy                               v1.32.1                                    e29f9c7391fd   2 months ago    94MB
flannel/flannel                                          v0.26.3                                    6833ea95066a   2 months ago    83.4MB
registry.k8s.io/ingress-nginx/controller                 <none>                                     a4a8af0db089   2 months ago    302MB
registry.k8s.io/ingress-nginx/kube-webhook-certgen       <none>                                     6595b1857d40   2 months ago    66.1MB
quay.io/metallb/speaker                                  v0.14.9                                    dacabb789863   3 months ago    127MB
quay.io/metallb/controller                               v0.14.9                                    48c6a3e363a2   3 months ago    70.4MB
bitnami/kafka                                            3.5.2                                      21bd84c8365d   3 months ago    638MB
flannel/flannel-cni-plugin                               v1.6.0-flannel1                            c9ce14f3932d   5 months ago    10.6MB
busybox                                                  latest                                     ff7a7936e930   5 months ago    4.28MB
busybox                                                  <none>                                     31311c5853a2   5 months ago    4.27MB
registry.k8s.io/metrics-server/metrics-server            v0.7.2                                     48d9cfaaf390   6 months ago    67.1MB
registry.k8s.io/kube-proxy                               v1.31.0                                    ad83b2ca7b09   7 months ago    91.5MB
registry.k8s.io/coredns/coredns                          v1.11.3                                    c69fa2e9cbf5   7 months ago    61.8MB
nicolaka/netshoot                                        latest                                     27b858cdcd8a   10 months ago   542MB
nicolaka/netshoot                                        v0.13                                      27b858cdcd8a   10 months ago   542MB
quay.io/frrouting/frr                                    9.1.0                                      e81800e2198c   16 months ago   163MB
registry.k8s.io/pause                                    3.9                                        e6f181688397   2 years ago     744kB

root@worker1:~# docker image rm python:3.13
Untagged: python:3.13
Untagged: python@sha256:385ccb8304f6330738a6d9e6fa0bd7608e006da7e15bc52b33b0398e1ba4a15b
Deleted: sha256:36d17f72f4f3630dbc93a0b2fe6f7e61179c597cbef32f815b34f70ef1e402f2
Deleted: sha256:ffee0d5738909aa4f63deb3e2cda7233e5caa8168014dfd7f647a130fa8a2d61
Deleted: sha256:abedb6642a36d2454dc03ced4dda571a0d15543168eaaab10b528f61d0e1344d
Deleted: sha256:995fa315e5445d8ecdeaaaf1d0fc52cd4aaee1014a838e57203ec0e3e5cc848d
Deleted: sha256:19499b1b05655fb8dfdb97d2d70be8a37d8be186b2ee54195d38973451b642c3
Deleted: sha256:61c887cfa58ed480aa22fc34dbb933dd29538b13aab89847e071e5253d40e2d6
Deleted: sha256:70c8762a14802e4ea0362748fca2ae2593b7866d954f915bae51cae1fa436297
Deleted: sha256:01c9a2a5f23727d0aab91da9d479286e25780d50b574f1a9df47ca850a88b591


$ k scale deployment http-server --replicas=7
deployment.apps/http-server scaled

$ k get pods -o wide
NAME                           READY   STATUS            RESTARTS   AGE   IP             NODE      NOMINATED NODE   READINESS GATES
http-server-756f76f767-crfsj   0/1     PodInitializing   0          4s    10.244.3.43    worker3   <none>           <none>
http-server-756f76f767-hzbqh   0/1     PodInitializing   0          4s    10.244.3.45    worker3   <none>           <none>
http-server-756f76f767-rftdf   0/1     PodInitializing   0          4s    10.244.3.42    worker3   <none>           <none>
http-server-756f76f767-rrlhk   0/1     PodInitializing   0          4s    10.244.3.46    worker3   <none>           <none>
http-server-756f76f767-sftsg   0/1     PodInitializing   0          4s    10.244.1.184   worker1   <none>           <none>
http-server-756f76f767-vkxf8   0/1     PodInitializing   0          4s    10.244.1.183   worker1   <none>           <none>
http-server-756f76f767-z4khr   0/1     PodInitializing   0          4s    10.244.3.44    worker3   <none>           <none>
```

So now most pods were scheduled onto worker3 which already had a python image, due to topologySpreadConstraints two pods were anyway scheduled onto worker1.
