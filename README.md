# (optional) Preperation for demo

Build the artificat, create a docker image, and publish it

```
./mvnw clean package
docker build -t emayssatware/test-envoy-ext-authz:latest .
docker login
docker push emayssatware/test-envoy-ext-authz:latest
```

# Demo1

```
kubectl create ns demo1
skaffold deploy
kubectl logs -f authz -n demo1
```

In another terminal
```
kubectl attach -it curl -n demo1
# in curl pod
curl -v envoy:80/deny            # Returns a 403
curl -v envoy:80/allow
curl -v invoker:8002/deny        # Here we bypass the AuthZ :-(
curl -v invoker:8002/allow
exit
# exit curl pod
```

Delete all but authZ server
```
pushd ./in/kustomize; kubectl delete -f invoker-pod.yaml -f envoy-pod.yaml -f curl-pod.yaml -n demo1; popd
```

# Demo2: same with a service mesh

Install istio

```
curl -L https://istio.io/downloadIstio | sh -
./istioctl version
# 1.9.0
istioctl install --set profile=default
kubectl label ns default istio-injection=enabled
```

Edit the mesh configuration with the following command

```
kubectl edit configmap istio -n istio-system

# Insert the 
apiVersion: v1
data:
  mesh: |-
    # INSERT BELOW
    extensionProviders:
    - name: "authz-demo1"
      envoyExtAuthzGrpc:
        service: "authz.demo1.svc.cluster.local"
        port: "9000"
    # KEEP THE REST OF THE EXISTING CONFIGURATION AS IS
    defaultConfig:
...
```

and refresh istiod

```
kubectl rollout restart deployment/istiod -n istio-system
```

Pre-load the configuration for the invoker

```
kubectl apply -f ./in/invoker-config.yaml
```

Now deploy the invoker and send curl requests

```
cat ./in/invoker-pod.yaml
kubectl apply -f ./in/invoker-pod.yaml
```

Curl the invoker through the ingress gateway

```
# kubectl get svc istio-ingressgateway -n istio-system
INGRESS_URL=http://127.0.0.1

curl -v ${INGRESS_URL}/deny          # Returns a 403
curl -v ${INGRESS_URL}/allow         # Returns a 202
```
