# k8s-training


# Install

Install nginx ingress controller
see: https://kubernetes.github.io/ingress-nginx/deploy/#quick-start


```
# export KUBECONFIG=/etc/kubernetes/admin.conf

# helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace

NAME: ingress-nginx
LAST DEPLOYED: Fri Feb 21 11:04:58 2025
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```


Create our custom resources:
```
# kubectl apply  -f namespace.yaml 
namespace/home created

# kubectl apply  -n home -f deployment.yaml -f ingress.yaml -f service.yaml 
deployment.apps/http-server created
ingress.networking.k8s.io/main created
service/http-server created
```

# Testing pod and service (needs socat)

First test with port-forward:
```
# kubectl get pods -n home -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
http-server-56bb7f7b5b-njp4p   1/1     Running   0          91m   10.244.3.18   worker2   <none>           <none>

# kubectl port-forward -v6 -n home pod/http-server-56bb7f7b5b-njp4p 8000
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
Handling connection for 8000
E0221 12:50:20.690058   53094 portforward.go:424] "Unhandled Error" err="an error occurred forwarding 8000 -> 8000: error forwarding port 8000 to pod 3e54eede086ee2a1a538405b4c9e62d11f670fffdd98a364a64db987839a38b2, uid : unable to do port forwarding: socat not found"
I0221 12:50:20.691650   53094 tunneling_connection.go:67] client:tunneling connection NextReader() error: read tcp 10.128.0.16:39096->10.128.0.16:6443: use of closed network connection
error: lost connection to pod
```

Error `unable to do port forwarding: socat not found`, solution manually install socat on all 4 machines (master and 3 workers).
```
apt install -y socat
```

Test again:
```
# kubectl port-forward -n home pod/http-server-56bb7f7b5b-njp4p 8000
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
Handling connection for 8000
Handling connection for 8000


# curl -v 'http://localhost:8000/index.html'
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /index.html HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: SimpleHTTP/0.6 Python/3.13.2
< Date: Fri, 21 Feb 2025 12:56:06 GMT
< Content-type: text/html
< Content-Length: 34
< Last-Modified: Fri, 21 Feb 2025 11:13:52 GMT
< 
<html><p>Hellow world!</p></html>
* Closing connection 0


# kubectl get services -A -o wide
NAMESPACE       NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
default         kubernetes                           ClusterIP      10.255.0.1      <none>        443/TCP                      26d    <none>
home            http-server                          ClusterIP      10.255.36.158   <none>        80/TCP                       112m   app=http-server
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.255.44.53    <pending>     80:32619/TCP,443:30357/TCP   120m   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.255.33.156   <none>        443/TCP                      120m   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
kube-system     kube-dns                             ClusterIP      10.255.0.10     <none>        53/UDP,53/TCP,9153/TCP       26d    k8s-app=kube-dns

# kubectl port-forward -v1 -n home service/http-server 8000:mainhttp
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000

# curl 'http://localhost:8000/index.html'
<html><p>Hellow world!</p></html>

```

Regarding port-forwarding to service you can only forward to a defined port in the service. Thats why here 'mainhttp' is used.

# Testing ingress (needs socat)

Ok, pod works, now test ingress, see: https://kubernetes.github.io/ingress-nginx/deploy/#local-testing
To test we forward traffic from outside to the actual controller that implements the rules:
```
# kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8000:80
Forwarding from 127.0.0.1:8000 -> 80
Forwarding from [::1]:8000 -> 80
Handling connection for 8000
Handling connection for 8000
```


Test that bad hostname does not work:
```
# curl -vv --header 'Host: wrong.hostname.otus' 'http://localhost:8000/index.html'
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /index.html HTTP/1.1
> Host: wrong.otus
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Fri, 21 Feb 2025 14:36:29 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host localhost left intact
```


Test that correct hostname + index.html works
```
# curl -vv --header 'Host: homework.otus' 'http://localhost:8000/index.html'
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /index.html HTTP/1.1
> Host: homework.otus
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Fri, 21 Feb 2025 14:36:22 GMT
< Content-Type: text/html
< Content-Length: 34
< Connection: keep-alive
< Last-Modified: Fri, 21 Feb 2025 11:13:52 GMT
< 
<html><p>Hellow world!</p></html>
* Connection #0 to host localhost left intact
```


Test that correct hostname + /homepage works
```
# curl -vv --header 'Host: homework.otus' 'http://localhost:8000/homepage'
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /homepage HTTP/1.1
> Host: homework.otus
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Fri, 21 Feb 2025 15:00:10 GMT
< Content-Type: text/html
< Content-Length: 34
< Connection: keep-alive
< Last-Modified: Fri, 21 Feb 2025 11:13:52 GMT
< 
<html><p>Hellow world!</p></html>
* Connection #0 to host localhost left intact
```

Test that correct hostname + /homexxxxxx does NOT work
```
# curl -vv --header 'Host: homework.otus' 'http://localhost:8000/homexxxxxx'
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /homexxxxxx HTTP/1.1
> Host: homework.otus
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Fri, 21 Feb 2025 15:02:31 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host localhost left intact
```

# Nginx behaiviour

All is per requirements, unfortunatelly there are still some problems left:

- can not specify /index.html as Exact path in nginx, because of strict-validate-path-type check, see: https://devops.stackexchange.com/questions/19915/ingress-failing-due-to-error-path-cannot-be-used-with-pathtype-prefix

- because of that, requesting /index.xxxxx is valid

- /homepage is matched in Prefix manner, so requesting /hostnamexxxxxx is also valid

This behaviour is specific to nginx ingress controller.


# Expose internet access

see: https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
see: https://kubernetes.io/docs/concepts/services-networking/service/#external-ips


### Using MetalLB to provision loadbalancer

see: https://kubernetes.github.io/ingress-nginx/deploy/baremetal/

For completenes current node ip addresses:

```
# yc compute instances list                                                           
+---------+---------+----------------+-------------+
|  NAME   | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+---------+---------+----------------+-------------+
| master  | RUNNING | 158.160.61.136 | 10.128.0.16 |
| worker1 | RUNNING | 158.160.36.172 | 10.128.0.25 |
| worker2 | RUNNING | 158.160.33.91  | 10.128.0.26 |
| worker3 | RUNNING | 158.160.40.157 | 10.128.0.3  |
+---------+---------+----------------+-------------+
```

Install metal-lb:

```
# helm repo add metallb https://metallb.github.io/metallb

# helm install metallb metallb/metallb --namespace metallb --create-namespace

# k get pods -A -o wide
NAMESPACE       NAME                                       READY   STATUS    RESTARTS        AGE     IP            NODE      NOMINATED NODE   READINESS GATES
home            http-server-56bb7f7b5b-njp4p               1/1     Running   3 (155m ago)    5d20h   10.244.3.23   worker2   <none>           <none>
ingress-nginx   ingress-nginx-controller-cd9d6bbd7-5t7j5   1/1     Running   0               19m     10.244.2.26   worker3   <none>           <none>
kube-flannel    kube-flannel-ds-b5gvw                      1/1     Running   13 (153m ago)   31d     10.128.0.25   worker1   <none>           <none>
kube-flannel    kube-flannel-ds-lxtzt                      1/1     Running   12 (153m ago)   31d     10.128.0.3    worker3   <none>           <none>
kube-flannel    kube-flannel-ds-vklr7                      1/1     Running   12 (155m ago)   31d     10.128.0.16   master    <none>           <none>
kube-flannel    kube-flannel-ds-wjmtv                      1/1     Running   12 (153m ago)   31d     10.128.0.26   worker2   <none>           <none>
kube-system     coredns-7c65d6cfc9-pk4xt                   1/1     Running   2 (155m ago)    35h     10.244.0.14   master    <none>           <none>
kube-system     coredns-7c65d6cfc9-zc2sr                   1/1     Running   5 (155m ago)    7d5h    10.244.0.13   master    <none>           <none>
kube-system     etcd-master                                1/1     Running   8 (155m ago)    31d     10.128.0.16   master    <none>           <none>
kube-system     kube-apiserver-master                      1/1     Running   8 (155m ago)    31d     10.128.0.16   master    <none>           <none>
kube-system     kube-controller-manager-master             1/1     Running   8 (155m ago)    31d     10.128.0.16   master    <none>           <none>
kube-system     kube-proxy-6k7fg                           1/1     Running   8 (155m ago)    31d     10.128.0.16   master    <none>           <none>
kube-system     kube-proxy-77njz                           1/1     Running   7 (155m ago)    31d     10.128.0.3    worker3   <none>           <none>
kube-system     kube-proxy-d2nmb                           1/1     Running   7 (155m ago)    31d     10.128.0.26   worker2   <none>           <none>
kube-system     kube-proxy-std4j                           1/1     Running   7 (155m ago)    31d     10.128.0.25   worker1   <none>           <none>
kube-system     kube-scheduler-master                      1/1     Running   2 (155m ago)    34h     10.128.0.16   master    <none>           <none>
metallb         metallb-controller-8474b54bc4-sbr5h        1/1     Running   0               38s     10.244.1.29   worker1   <none>           <none>
metallb         metallb-speaker-66m82                      4/4     Running   0               38s     10.128.0.3    worker3   <none>           <none>
metallb         metallb-speaker-bn2x2                      4/4     Running   0               38s     10.128.0.25   worker1   <none>           <none>
metallb         metallb-speaker-qqllz                      4/4     Running   0               38s     10.128.0.26   worker2   <none>           <none>
metallb         metallb-speaker-ss9hk                      4/4     Running   0               38s     10.128.0.16   master    <none>           <none>
```

Add ip address pool. Use the external ip given out to nodes. Looks like no adversiting is needed from MetalLB because these ip already lead to nodes.
Actually when outside traffic hits the node network card, its already using 10.x.x.x as destination ip.
Confirmed with tcpdump on master node (while client send `curl -vvv http://158.160.61.136:12345/` request):
```
# sudo tcpdump -i any port 12345
tcpdump: data link type LINUX_SLL2
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes

07:45:43.536322 eth0  In  IP 79.134.37.172.57932 > master.ru-central1.internal.12345: Flags [S], seq 3720095364, win 64240, options [mss 1460,sackOK,TS val 744837090 ecr 0,nop,wscale 7], length 0
07:45:43.536368 eth0  Out IP master.ru-central1.internal.12345 > 79.134.37.172.57932: Flags [R.], seq 0, ack 3720095365, win 0, length 0

^C
2 packets captured
3 packets received by filter
0 packets dropped by kernel

# nslookup master.ru-central1.internal
Server:		10.128.0.2
Address:	10.128.0.2#53

Name:	master.ru-central1.internal
Address: 10.128.0.16
```

Check services before creating address pool:
```
# k get svc -A
NAMESPACE       NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.255.0.1      <none>        443/TCP                      32d
home            http-server                          ClusterIP      10.255.36.158   <none>        8000/TCP                     5d20h
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.255.225.92   <pending>     80:32646/TCP,443:31442/TCP   30m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.255.163.11   <none>        443/TCP                      30m
kube-system     kube-dns                             ClusterIP      10.255.0.10     <none>        53/UDP,53/TCP,9153/TCP       32d
metallb         metallb-webhook-service              ClusterIP      10.255.92.196   <none>        443/TCP                      12m
```

Create metallb address pool with master and worker1 addresses.
```
# k apply -f metallb-ip-address-pool.yaml -n metallb

# k get ipaddresspool -A
NAMESPACE   NAME      AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
metallb     default   false         false             ["158.160.61.136/32","158.160.36.172/32"]
```

Check metallb controller logs that ip was assigned:
```
# k logs -f metallb-controller-8474b54bc4-sbr5h -n metallb
{"caller":"service.go:180","event":"ipAllocated","ip":["158.160.61.136"],"level":"info","msg":"IP address assigned by controller","ts":"2025-02-27T07:52:56Z"}
{"caller":"main.go:127","event":"serviceUpdated","level":"info","msg":"updated service object","ts":"2025-02-27T07:52:56Z"}
{"caller":"service_controller_reload.go:119","controller":"ServiceReconciler - reprocessAll","end reconcile":"metallbreload/reload","level":"info","ts":"2025-02-27T07:52:56Z"}
{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"ingress-nginx/ingress-nginx-controller","ts":"2025-02-27T07:52:56Z"}
{"caller":"main.go:127","event":"serviceUpdated","level":"info","msg":"updated service object","ts":"2025-02-27T07:52:56Z"}
{"caller":"service_controller.go:115","controller":"ServiceReconciler","end reconcile":"ingress-nginx/ingress-nginx-controller","level":"info","ts":"2025-02-27T07:52:56Z"}
```

Check services:
```
# k get svc -A 
NAMESPACE       NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.255.0.1      <none>           443/TCP                      32d
home            http-server                          ClusterIP      10.255.36.158   <none>           8000/TCP                     5d20h
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.255.225.92   158.160.61.136   80:32646/TCP,443:31442/TCP   35m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.255.163.11   <none>           443/TCP                      35m
kube-system     kube-dns                             ClusterIP      10.255.0.10     <none>           53/UDP,53/TCP,9153/TCP       32d
metallb         metallb-webhook-service              ClusterIP      10.255.92.196   <none>           443/TCP                      17m
```

But trying to reach service on the external ip address with curl, does not work!
This appears to be because metal lb added rules that work on destination_ip=158.160.61.136 packets.
However in yandex cloud such packets never reach the machine, incoming packets are DNAT'ed and so destination ip
becomes e.g. 10.x.x.x. Such packets do reach the machine, but they are not part of metallb address.

It seems tempting to re-use an internal NodeIP as a metal-lb address, however nginx-ingress-controller docs warn against this:
```
This pool can be defined through IPAddressPool objects in the same namespace as the MetalLB controller. This pool of IPs must be dedicated to MetalLB's use, you can't reuse the Kubernetes node IPs or IPs handed out by a DHCP server
```
Which makes sense, because then traffic between nodes would get messed up. So it seems that everything would work if only traffic was not DNAT'ed,
so if only `curl http://158.160.61.136/` would actually reach the node with destination_ip=158.160.61.136 and not destination_ip=10.128.0.16 as it is now.

At this point lets try using a floating IPv4 address, buy one in cloud: 89.169.150.171

Create metallb l2 advertisement:
```
# k apply -n metallb -f metallb-l2-advertisement.yaml

# k get svc -A
NAMESPACE       NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.255.0.1      <none>           443/TCP                      32d
home            http-server                          ClusterIP      10.255.36.158   <none>           8000/TCP                     6d1h
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.255.225.92   89.169.150.171   80:32646/TCP,443:31442/TCP   5h43m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.255.163.11   <none>           443/TCP                      5h43m
kube-system     kube-dns                             ClusterIP      10.255.0.10     <none>           53/UDP,53/TCP,9153/TCP       32d
metallb         metallb-webhook-service              ClusterIP      10.255.92.196   <none>           443/TCP                      5h25m
```

Check that service was advertised and it is - "announcing from node with protocol layer2":
```
# k events svc/ingress-nginx-controller -n ingress-nginx
LAST SEEN   TYPE     REASON            OBJECT                             MESSAGE
56m         Normal   ClearAssignment   Service/ingress-nginx-controller   current IP for "ingress-nginx/ingress-nginx-controller" not allowed by config, will attempt for new IP assignment: ["158.160.61.136"] is not allowed in config
56m         Normal   IPAllocated       Service/ingress-nginx-controller   Assigned IP ["89.169.150.171"]
11m         Normal   nodeAssigned      Service/ingress-nginx-controller   announcing from node "worker3" with protocol "layer2"
```

Check that advertisement went out from network card, check from master and check from worker1:
```
root@master:~# arping 89.169.150.171
arping: lookup dev: No matching interface found using getifaddrs().
arping: Unable to automatically find interface to use. Is it on the local LAN?
arping: Use -i to manually specify interface. Guessing interface eth0.
ARPING 89.169.150.171
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=0 time=9.407 usec
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=1 time=156.875 usec
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=2 time=141.916 usec
^C
--- 89.169.150.171 statistics ---
3 packets transmitted, 3 packets received,   0% unanswered (0 extra)
rtt min/avg/max/std-dev = 0.009/0.103/0.157/0.066 ms


root@worker1:~# arping 89.169.150.171
arping: lookup dev: No matching interface found using getifaddrs().
arping: Unable to automatically find interface to use. Is it on the local LAN?
arping: Use -i to manually specify interface. Guessing interface eth0.
ARPING 89.169.150.171
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=0 time=8.516 usec
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=1 time=121.845 usec
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=2 time=119.261 usec
58 bytes from 00:00:5e:00:01:00 (89.169.150.171): index=3 time=125.565 usec
^C
--- 89.169.150.171 statistics ---
4 packets transmitted, 4 packets received,   0% unanswered (0 extra)
rtt min/avg/max/std-dev = 0.009/0.094/0.126/0.049 ms
```

However adversitements for 89.169.150.171 never arrive. 
This probably means arp is blocked to protect agains mac spoofing, see: https://metallb.io/troubleshooting/
```
root@worker1:~# tcpdump -n -i eth0 arp 
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:33.970922 ARP, Request who-has 10.128.0.25 tell 10.128.0.2, length 28
13:16:33.970930 ARP, Reply 10.128.0.25 is-at d0:0d:2b:5b:f8:82, length 28
13:16:41.711622 ARP, Request who-has 10.128.0.26 tell 10.128.0.25, length 28
13:16:41.711768 ARP, Reply 10.128.0.26 is-at 00:00:5e:00:01:00, length 28
13:16:43.971116 ARP, Request who-has 10.128.0.25 tell 10.128.0.2, length 28
13:16:43.971140 ARP, Reply 10.128.0.25 is-at d0:0d:2b:5b:f8:82, length 28
```

This whole issue is due to one-to-one NAT in yc:
 - see: https://yandex.cloud/ru/docs/vpc/concepts/address
 - see: https://yandex.cloud/ru/docs/compute/concepts/network

Basically a VM gets a private ipv4 address, but all public access is done via one-to-one NAT.
It seems impossible to directly access internet without this NAT.






### Trying to expose via external-ip did not work due to flannel's external-node-ip / internal-node-ip

see: https://kubernetes.io/docs/concepts/services-networking/service/#external-ips

For completenes current node ip addresses:
```
$ yc compute instances list                                                         
+---------+---------+-----------------+-------------+
|  NAME   | STATUS  |   EXTERNAL IP   | INTERNAL IP |
+---------+---------+-----------------+-------------+
| master  | RUNNING | 158.160.41.22   | 10.128.0.16 |
| worker1 | RUNNING | 158.160.105.145 | 10.128.0.25 |
| worker2 | RUNNING | 89.169.129.38   | 10.128.0.26 |
| worker3 | RUNNING | 158.160.46.75   | 10.128.0.3  |
+---------+---------+-----------------+-------------+
```

Start by exposing just the http-server service and ignore nginx ingress controller for now.

Apply the service-external-ip.yaml

```

# kubectl get svc -A -o wide
NAMESPACE     NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE    SELECTOR
default       kubernetes    ClusterIP   10.255.0.1      <none>        443/TCP                  31d    <none>
home          http-server   ClusterIP   10.255.36.158   <none>        8000/TCP                 5d5h   app=http-server
kube-system   kube-dns      ClusterIP   10.255.0.10     <none>        53/UDP,53/TCP,9153/TCP   31d    k8s-app=kube-dns


# kubectl apply -n home -f service-external-ip.yaml 
service/http-server-external-ip created

# kubectl get svc -A -o wide
NAMESPACE     NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP                                   PORT(S)                  AGE    SELECTOR
default       kubernetes                ClusterIP   10.255.0.1      <none>                                        443/TCP                  31d    <none>
home          http-server               ClusterIP   10.255.36.158   <none>                                        8000/TCP                 5d5h   app=http-server
home          http-server-external-ip   ClusterIP   10.255.140.97   158.160.105.145,89.169.129.38,158.160.46.75   8000/TCP                 7s     app=http-server
kube-system   kube-dns                  ClusterIP   10.255.0.10     <none>                                        53/UDP,53/TCP,9153/TCP   31d    k8s-app=kube-dns

# kubectl get pods -A -o wide
NAMESPACE      NAME                             READY   STATUS    RESTARTS        AGE     IP            NODE      NOMINATED NODE   READINESS GATES
home           http-server-56bb7f7b5b-njp4p     1/1     Running   2 (7h5m ago)    5d5h    10.244.3.20   worker2   <none>           <none>
kube-flannel   kube-flannel-ds-b5gvw            1/1     Running   11 (7h4m ago)   30d     10.128.0.25   worker1   <none>           <none>
kube-flannel   kube-flannel-ds-lxtzt            1/1     Running   10 (7h5m ago)   30d     10.128.0.3    worker3   <none>           <none>
kube-flannel   kube-flannel-ds-vklr7            1/1     Running   11 (7h5m ago)   31d     10.128.0.16   master    <none>           <none>
kube-flannel   kube-flannel-ds-wjmtv            1/1     Running   10 (7h3m ago)   30d     10.128.0.26   worker2   <none>           <none>
kube-system    coredns-7c65d6cfc9-pk4xt         1/1     Running   1 (7h5m ago)    19h     10.244.0.12   master    <none>           <none>
kube-system    coredns-7c65d6cfc9-zc2sr         1/1     Running   4 (7h5m ago)    6d14h   10.244.0.11   master    <none>           <none>
kube-system    etcd-master                      1/1     Running   7 (7h5m ago)    30d     10.128.0.16   master    <none>           <none>
kube-system    kube-apiserver-master            1/1     Running   7 (7h5m ago)    30d     10.128.0.16   master    <none>           <none>
kube-system    kube-controller-manager-master   1/1     Running   7 (7h5m ago)    30d     10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-6k7fg                 1/1     Running   7 (18h ago)     30d     10.128.0.16   master    <none>           <none>
kube-system    kube-proxy-77njz                 1/1     Running   6 (7h5m ago)    30d     10.128.0.3    worker3   <none>           <none>
kube-system    kube-proxy-d2nmb                 1/1     Running   6 (7h5m ago)    30d     10.128.0.26   worker2   <none>           <none>
kube-system    kube-proxy-std4j                 1/1     Running   6 (7h4m ago)    30d     10.128.0.25   worker1   <none>           <none>
kube-system    kube-scheduler-master            1/1     Running   1 (18h ago)     19h     10.128.0.16   master    <none>           <none>
```

At this point everything is set-up to work, however curl still fails:
```
$ curl -v --connect-to 'homework.otus:8000:89.169.129.38:8000' 'http://homework.otus:8000/xxxx'
* Connecting to hostname: 89.169.129.38
* Connecting to port: 8000
*   Trying 89.169.129.38:8000...
* connect to 89.169.129.38 port 8000 from 192.168.0.136 port 36964 failed: Connection refused
* Failed to connect to 89.169.129.38 port 8000 after 64 ms: Could not connect to server
* closing connection #0
curl: (7) Failed to connect to 89.169.129.38 port 8000 after 64 ms: Could not connect to server
```

Checking the tcpdump on the worker2 node, traffic reaches the node but is immediately [R.] i.e. connection is reset:
```
root@worker2# sudo tcpdump -i any port 8000
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
16:41:56.718089 eth0  In  IP 79.134.37.172.58464 > worker2.ru-central1.internal.8000: Flags [S], seq 4220012833, win 64240, options [mss 1460,sackOK,TS val 75387961 ecr 0,nop,wscale 7], length 0
16:41:56.718147 eth0  Out IP worker2.ru-central1.internal.8000 > 79.134.37.172.58464: Flags [R.], seq 0, ack 4220012834, win 0, length 0
```

Checking the iptable rules, they exist and should work apparently (node ip=89.169.129.38, virtual service ip=10.255.140.97):
```
# sudo iptables-save | grep 89.169.129.38
-A KUBE-SERVICES -d 89.169.129.38/32 -p tcp -m comment --comment "home/http-server-external-ip:mainhttp external IP" -j KUBE-EXT-MEREAWZIC2FTOY2S


# sudo iptables-save | grep 10.255.140.97
-A KUBE-SERVICES -d 10.255.140.97/32 -p tcp -m comment --comment "home/http-server-external-ip:mainhttp cluster IP" -j KUBE-SVC-MEREAWZIC2FTOY2S
-A KUBE-SVC-MEREAWZIC2FTOY2S ! -s 10.244.0.0/16 -d 10.255.140.97/32 -p tcp -m comment --comment "home/http-server-external-ip:mainhttp cluster IP" -j KUBE-MARK-MASQ
```

What turned out to be the root cause is flannel, because it is using internal-node-ip for interfacing and routing:
```
# kubectl get nodes -o yaml | grep ip
      flannel.alpha.coreos.com/public-ip: 10.128.0.16
      flannel.alpha.coreos.com/public-ip: 10.128.0.25
      flannel.alpha.coreos.com/public-ip: 10.128.0.26
      flannel.alpha.coreos.com/public-ip: 10.128.0.3
```

So it does not know how to route external ip addresses.
See: https://github.com/k3s-io/k3s/issues/6177
See: --flannel-external-ip at https://docs.k3s.io/networking/basic-network-options


