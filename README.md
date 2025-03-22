(more notes on storage in kubernetes-templating lab: https://github.com/temach/k8s-training/tree/kubernetes-templating )


# Create custom storage class and pv

Manually create directories on nodes worker1 and worker3:
```
$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1
mkdir -p /opt/my-local-storage/worker1-pv1
mkdir -p /opt/my-local-storage/worker1-pv2

$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker3
mkdir -p /opt/my-local-storage/worker3-pv6
mkdir -p /opt/my-local-storage/worker3-pv7
```

Deploy yaml with local storage provisioner (see: https://kubernetes.io/docs/concepts/storage/volumes/#local ):
```
$ k apply -f storage.yaml 
storageclass.storage.k8s.io/local-storage created
persistentvolume/worker1-pv1 created
persistentvolume/worker1-pv2 created
persistentvolume/worker3-pv6 created
persistentvolume/worker3-pv7 created

$ k get pv -o wide
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE    VOLUMEMODE
worker1-pv1   1Gi        RWO            Retain           Available           local-storage   <unset>                          2m8s   Filesystem
worker1-pv2   1Gi        RWO            Retain           Available           local-storage   <unset>                          2m8s   Filesystem
worker3-pv6   1Gi        RWO            Retain           Available           local-storage   <unset>                          2m8s   Filesystem
worker3-pv7   1Gi        RWO            Retain           Available           local-storage   <unset>                          2m7s   Filesystem

$ k get storageclass
NAME                      PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-storage (default)   kubernetes.io/no-provisioner   Retain          WaitForFirstConsumer   false                  2m53s
```

When recreating volumes, must to manually remove claimRef in pv. 
Also must manually clean /opt/my-local-storage/worker1-pv*/ directories to empty volumes.

# Deploy application

Deploy and check for errors:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created

$ k get pod -A -o wide
NAMESPACE      NAME                             READY   STATUS    RESTARTS       AGE    IP            NODE      NOMINATED NODE   READINESS GATES
default        http-server-6d67c5c7fb-267bb     0/1     Pending   0              22s    <none>        <none>    <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh            1/1     Running   7 (68m ago)    6d     10.128.0.16   master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4            1/1     Running   20 (67m ago)   6d1h   10.128.0.26   worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7            1/1     Running   7 (69m ago)    6d     10.128.0.3    worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk            1/1     Running   6 (69m ago)    6d     10.128.0.25   worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw         1/1     Running   4 (69m ago)    6d     10.244.2.31   worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   16 (69m ago)   24d    10.244.0.29   master    <none>           <none>
kube-system    etcd-master                      1/1     Running   22 (69m ago)   54d    10.128.0.16   master    <none>           <none>
kube-system    kube-apiserver-master            1/1     Running   22 (69m ago)   54d    10.128.0.16   master    <none>           <none>
kube-system    kube-controller-manager-master   1/1     Running   23 (69m ago)   54d    10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-bp57z                 1/1     Running   9 (69m ago)    8d     10.128.0.25   worker1   <none>           <none>
kube-system    kube-proxy-hkklk                 1/1     Running   8 (69m ago)    8d     10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-x4qcl                 1/1     Running   5 (11h ago)    6d1h   10.128.0.26   worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                 1/1     Running   6 (69m ago)    6d1h   10.128.0.3    worker3   <none>           <none>
kube-system    kube-scheduler-master            1/1     Running   18 (69m ago)   24d    10.128.0.16   master    <none>           <none>

$ k events
LAST SEEN   TYPE      REASON              OBJECT                              MESSAGE
30s         Warning   FailedScheduling    Pod/http-server-6d67c5c7fb-267bb    0/4 nodes are available: persistentvolumeclaim "pvc-basic" not found. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
30s         Normal    SuccessfulCreate    ReplicaSet/http-server-6d67c5c7fb   Created pod: http-server-6d67c5c7fb-267bb
30s         Normal    ScalingReplicaSet   Deployment/http-server              Scaled up replica set http-server-6d67c5c7fb from 0 to 1
```

Must deploy pvc-basic and cm-basic as well:
```
$ k apply -f pvc.yaml -f cm.yaml
persistentvolumeclaim/pvc-basic created
configmap/cm-basic created

$ k get pvc -o wide
NAME        STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE    VOLUMEMODE
pvc-basic   Bound    worker1-pv1   1Gi        RWO            local-storage   <unset>                 110s   Filesystem

$ k get pods -A
NAMESPACE      NAME                             READY   STATUS    RESTARTS       AGE
default        http-server-6d67c5c7fb-267bb     1/1     Running   0              4m23s
kube-flannel   kube-flannel-ds-hjwfh            1/1     Running   7 (72m ago)    6d
kube-flannel   kube-flannel-ds-q2gl4            1/1     Running   20 (71m ago)   6d1h
kube-flannel   kube-flannel-ds-sq6s7            1/1     Running   7 (73m ago)    6d
kube-flannel   kube-flannel-ds-sx6qk            1/1     Running   6 (73m ago)    6d
kube-system    coredns-7c65d6cfc9-gmzxw         1/1     Running   4 (73m ago)    6d
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   16 (73m ago)   24d
kube-system    etcd-master                      1/1     Running   22 (73m ago)   54d
kube-system    kube-apiserver-master            1/1     Running   22 (73m ago)   54d
kube-system    kube-controller-manager-master   1/1     Running   23 (73m ago)   54d
kube-system    kube-proxy-bp57z                 1/1     Running   9 (73m ago)    8d
kube-system    kube-proxy-hkklk                 1/1     Running   8 (73m ago)    8d
kube-system    kube-proxy-x4qcl                 1/1     Running   5 (11h ago)    6d1h
kube-system    kube-proxy-z5ztj                 1/1     Running   6 (73m ago)    6d1h
kube-system    kube-scheduler-master            1/1     Running   18 (73m ago)   24d
```

App deployed sucessfully. Check its filesystem:
```
$ k debug -it --profile=sysadmin --image=nicolaka/netshoot:v0.13 -n default --target=server-container http-server-6d67c5c7fb-267bb

http-server-6d67c5c7fb-267bb  ~  cd /proc/1/root/homework/   

http-server-6d67c5c7fb-267bb  /proc/1/root/homework  ls -la
total 16
drwxrwsr-x    3 root     nobody        4096 Mar 22 19:38 .
drwxr-xr-x    1 root     root          4096 Mar 22 19:34 ..
drwxrwxrwx    3 root     root          4096 Mar 22 19:42 conf
-rw-r--r--    1 root     nobody          34 Mar 22 19:34 index.html

http-server-6d67c5c7fb-267bb  /proc/1/root/homework  find        
.
./index.html
./conf
./conf/..2025_03_22_19_42_08.1625199414
./conf/..2025_03_22_19_42_08.1625199414/file
./conf/file
./conf/..data

$ http-server-6d67c5c7fb-267bb  /proc/1/root/homework  cat conf/file 
favourite_food="pasta"
player_initial_lives="3"
file_name="user-interface.properties"
welcome_text="Hello from config map!"
```

Verify with HTTP request to /conf/file that full config map is returned:
```
$ k port-forward svc/http-server 9000:http-main
Forwarding from 127.0.0.1:9000 -> 8080
Forwarding from [::1]:9000 -> 8080

$ curl http://localhost:9000/   
<html><p>Hellow Sun Mar 23 12:40:11 AM +05 2025!</p></html>

$ curl -v http://localhost:9000/conf/file
* Host localhost:9000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:9000...
* Connected to localhost (::1) port 9000
* using HTTP/1.x
> GET /conf/file HTTP/1.1
> Host: localhost:9000
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: SimpleHTTP/0.6 Python/3.13.2
< Date: Sat, 22 Mar 2025 19:46:43 GMT
< Content-type: application/octet-stream
< Content-Length: 124
< Last-Modified: Sat, 22 Mar 2025 19:42:08 GMT
< 
favourite_food="pasta"
player_initial_lives="3"
file_name="user-interface.properties"
welcome_text="Hello from config map!"
* shutting down connection #0
```

Examining the backing storage asset (directory worker1-pv1:
```
$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1

root@worker1:~# cd /opt/my-local-storage/

root@worker1:/opt/my-local-storage# ls -la
total 16
drwxr-xr-x 4 root root           4096 Feb 20 04:37 .
drwxr-xr-x 4 root root           4096 Feb 20 04:36 ..
drwxrwsr-x 3 root nogroup        4096 Mar 22 19:38 worker1-pv1
drwxrwsr-x 4 root google-sudoers 4096 Feb 20 05:07 worker1-pv2

root@worker1:/opt/my-local-storage# cd worker1-pv1/

root@worker1:/opt/my-local-storage/worker1-pv1# find 
.
./index.html
./conf

root@worker1:/opt/my-local-storage/worker1-pv1# ls -la -R
.:
total 16
drwxrwsr-x 3 root nogroup 4096 Mar 22 19:38 .
drwxr-xr-x 4 root root    4096 Feb 20 04:37 ..
drwxr-sr-x 2 root nogroup 4096 Mar 22 19:34 conf
-rw-r--r-- 1 root nogroup   34 Mar 22 19:34 index.html

./conf:
total 8
drwxr-sr-x 2 root nogroup 4096 Mar 22 19:34 .
drwxrwsr-x 3 root nogroup 4096 Mar 22 19:38 ..
```

So the "conf" directory got created on the sotrage medium, however the contents of configmap are not created, they are only visible inside the container.


# Other storage experiments

### Scale replica +1

The initContainer in http-server write the time into index.html:
```
          command: ["sh", "-c"]
          args: ["echo \"<html><p>Hellow $(date)</p></html>\" > /init/index.html"]
```

Check if scaling will override the index.html and if the old replica will start reploying with new time.
```
$ k get pods -A
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE
default        http-server-5bf7c86586-9p5qd     1/1     Running   0               84s
kube-flannel   kube-flannel-ds-hjwfh            1/1     Running   7 (99m ago)     6d1h
kube-flannel   kube-flannel-ds-q2gl4            1/1     Running   20 (98m ago)    6d2h
kube-flannel   kube-flannel-ds-sq6s7            1/1     Running   7 (100m ago)    6d
kube-flannel   kube-flannel-ds-sx6qk            1/1     Running   6 (100m ago)    6d1h
kube-system    coredns-7c65d6cfc9-gmzxw         1/1     Running   4 (100m ago)    6d1h
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   16 (100m ago)   24d
kube-system    etcd-master                      1/1     Running   22 (100m ago)   54d
kube-system    kube-apiserver-master            1/1     Running   22 (100m ago)   54d
kube-system    kube-controller-manager-master   1/1     Running   23 (100m ago)   54d
kube-system    kube-proxy-bp57z                 1/1     Running   9 (100m ago)    8d
kube-system    kube-proxy-hkklk                 1/1     Running   8 (100m ago)    8d
kube-system    kube-proxy-x4qcl                 1/1     Running   5 (12h ago)     6d2h
kube-system    kube-proxy-z5ztj                 1/1     Running   6 (100m ago)    6d2h
kube-system    kube-scheduler-master            1/1     Running   18 (100m ago)   24d

$ k port-forward svc/http-server 9000:http-main
Forwarding from 127.0.0.1:9000 -> 8080
Forwarding from [::1]:9000 -> 8080

$ curl http://localhost:9000/
<html><p>Hellow Sat Mar 22 20:01:57 UTC 2025</p></html>

$ k scale --replicas=2 deployment http-server
deployment.apps/http-server scaled

$ k get pods -A -o wide
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE    IP             NODE      NOMINATED NODE   READINESS GATES
default        http-server-5bf7c86586-26k4t     1/1     Running   0               12m    10.244.1.131   worker1   <none>           <none>
default        http-server-5bf7c86586-9p5qd     1/1     Running   0               18m    10.244.1.130   worker1   <none>           <none>
kube-flannel   kube-flannel-ds-hjwfh            1/1     Running   7 (116m ago)    6d1h   10.128.0.16    master    <none>           <none>
kube-flannel   kube-flannel-ds-q2gl4            1/1     Running   20 (116m ago)   6d2h   10.128.0.26    worker2   <none>           <none>
kube-flannel   kube-flannel-ds-sq6s7            1/1     Running   7 (118m ago)    6d1h   10.128.0.3     worker3   <none>           <none>
kube-flannel   kube-flannel-ds-sx6qk            1/1     Running   6 (118m ago)    6d1h   10.128.0.25    worker1   <none>           <none>
kube-system    coredns-7c65d6cfc9-gmzxw         1/1     Running   4 (118m ago)    6d1h   10.244.2.31    worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   16 (118m ago)   24d    10.244.0.29    master    <none>           <none>
kube-system    etcd-master                      1/1     Running   22 (118m ago)   54d    10.128.0.16    master    <none>           <none>
kube-system    kube-apiserver-master            1/1     Running   22 (118m ago)   54d    10.128.0.16    master    <none>           <none>
kube-system    kube-controller-manager-master   1/1     Running   23 (118m ago)   54d    10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-bp57z                 1/1     Running   9 (118m ago)    8d     10.128.0.25    worker1   <none>           <none>
kube-system    kube-proxy-hkklk                 1/1     Running   8 (118m ago)    8d     10.128.0.16    master    <none>           <none>
kube-system    kube-proxy-x4qcl                 1/1     Running   5 (12h ago)     6d2h   10.128.0.26    worker2   <none>           <none>
kube-system    kube-proxy-z5ztj                 1/1     Running   6 (118m ago)    6d2h   10.128.0.3     worker3   <none>           <none>
kube-system    kube-scheduler-master            1/1     Running   18 (118m ago)   24d    10.128.0.16    master    <none>           <none>

$ curl http://localhost:9000/
<html><p>Hellow Sat Mar 22 20:08:12 UTC 2025</p></html>

$ yc compute ssh --identity-file /home/artem/.ssh/id_rsa --login artem --name worker1
root@worker1:# cat /opt/my-local-storage/worker1-pv1/index.html 
<html><p>Hellow Sat Mar 22 20:08:12 UTC 2025</p></html>
```

The index.html on storage medium was changed. Both pods started returning the later time (when second pod launched).

The PVC had `accessMode: - ReadWriteOnce` which did not stop second pod from updating index.html on the physical-volume.
see: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

Also note: these physical volumes have support for the volume capacity limit, nothing will stop folder from growing.


### test if storage limit is enforced for PV

local provisioner does not enforce PV limit.
see: https://kubernetes.io/docs/concepts/storage/volumes/#local

Attach to python pod and try to generate multiple 1GB files (PV is 1GB)
```
$ k exec -it http-server-5bf7c86586-9p5qd -- /bin/bash            
Defaulted container "server-container" out of: server-container, generate-index (init)

root@http-server-5bf7c86586-9p5qd:/# cd /homework/

root@http-server-5bf7c86586-9p5qd:/homework# ls -la
total 16
drwxrwsr-x 3 root nogroup 4096 Mar 22 19:38 .
drwxr-xr-x 1 root root    4096 Mar 22 20:01 ..
drwxrwxrwx 3 root root    4096 Mar 22 20:01 conf
-rw-r--r-- 1 root nogroup   56 Mar 22 20:08 index.html

root@http-server-5bf7c86586-9p5qd:/homework# dd if=/dev/zero of=dummy-1GB.data count=100 bs=10M
100+0 records in
100+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 1.03147 s, 1.0 GB/s

root@http-server-5bf7c86586-9p5qd:/homework# dd if=/dev/zero of=dummy-two-1GB.data count=100 bs=10M
100+0 records in
100+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 108.974 s, 9.6 MB/s

root@http-server-5bf7c86586-9p5qd:/homework# dd if=/dev/zero of=dummy-three-1GB.data count=100 bs=10M
100+0 records in
100+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 49.9898 s, 21.0 MB/s

root@http-server-5bf7c86586-9p5qd:/homework# ls -la
total 3072028
drwxrwsr-x 3 root nogroup       4096 Mar 22 20:45 .
drwxr-xr-x 1 root root          4096 Mar 22 20:01 ..
drwxrwxrwx 3 root root          4096 Mar 22 20:01 conf
-rw-r--r-- 1 root nogroup 1048576000 Mar 22 20:44 dummy-1GB.data
-rw-r--r-- 1 root nogroup 1048576000 Mar 22 20:45 dummy-three-1GB.data
-rw-r--r-- 1 root nogroup 1048576000 Mar 22 20:46 dummy-two-1GB.data
-rw-r--r-- 1 root nogroup         56 Mar 22 20:08 index.html

root@http-server-5bf7c86586-9p5qd:/homework# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          30G   12G   18G  40% /
tmpfs            64M     0   64M   0% /dev
/dev/vda2        30G   12G   18G  40% /homework
shm              64M     0   64M   0% /dev/shm
tmpfs           7.7G   12K  7.7G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs           3.9G     0  3.9G   0% /proc/acpi
tmpfs           3.9G     0  3.9G   0% /sys/firmware
```



### distributed dynamic storage (e.g. GlusterFS) over the node's local storage

see: https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta




