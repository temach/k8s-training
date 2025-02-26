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

### Simplest way via external-ip (looses source-ip)

Edit service to change type to NodePort and assign external IP.
The files are service-node-port-external-ip.yaml and values-node-port-external-ip.yaml.
Update helm values:
```


```

Install new service:
```


```



### Install LoadBalancer manager to provision EXTERNAL-IP for Ingress and allow out-of cluster access


