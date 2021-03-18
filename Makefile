KCL_NAMESPACE_NAME?= kjell

_default: demo_workflow

login_dockerhub:
	docker login

build: build_artifact build_image

build_artifact:
	./mvnw clean package

build_image:
	docker build -t emayssatware/test-envoy-ext-authz:latest .
	# skaffold build

push_image:
	docker push emayssatware/test-envoy-ext-authz:latest
	# skaffold build

deploy:
	skaffold run -n $(KCL_NAMESPACE_NAME)
	kubectl get po -n $(KCL_NAMESPACE_NAME)

undeploy:
	skaffold delete -n $(KCL_NAMESPACE_NAME)
	kubectl get po -n $(KCL_NAMESPACE_NAME)

demo_workflow:
	@echo
	@echo "* Show diagram for Zanzibar from RFC"
	@echo "* Explain what you are going to do ---> Developer perspective"
	@echo "* Show kjell diagram"
	@echo "kubectl get pod -A"
	@echo "cat envoy.yaml"
	@echo "skaffold run -n kjell"
	@echo "kubectl get pod -n kjell"
	@echo "pwd ; kubectl logs -f authz -n kjell # ktail authz -n kjell"
	@echo "kubectl attach -it curl -n kjell # kssh curl -n kjell"
	@echo "curl -v envoy:80/deny"
	@echo "curl -v envoy:80/allow"
	@echo " * bypass ... diagram!"
	@echo "curl -v invoker:8002/deny"
	@echo "curl -v invoker:8002/allow"
	@echo "* exit from curl pod!"
	@echo "pushd ./kube/kustomize; kubectl delete -f invoker-pod.yaml -f envoy-pod.yaml -f curl-pod.yaml -n kjell; popd"
	@echo "kubectl get pods -n kjell"
	@echo "cat ./kube/kustomize/invoker-pod.yaml"
	@echo " * one line demo ... watch carefully!"
	@echo "kubectl apply -f ./kube/kustomize/invoker-pod.yaml"
	@echo " * demo is done ...."
	@echo " * sorry let's validate ...."
	@echo "kubectl get pod -A"
	@echo "check authz logs!"
	@echo "curl -v http://my.domain.com/invoker/deny"
	@echo "curl -v http://my.domain.com/invoker/allow"
	@echo " * Q: Where is envoy? Where does it say that Authorization should be done by this authz pod?"
	@echo " * POINT: Completely transparent from the application"
	@echo "cat /Users/emayssat/workspaces/github.com/jpmoc/istio-knative-primer.git/in/invoker--kservice.yaml"
	@echo "kubectl apply -f  /Users/emayssat/workspaces/github.com/jpmoc/istio-knative-primer.git/in/invoker--kservice.yaml"
	@echo "curl -v http://invoker.default.example.com/deny"
	@echo "curl -v http://invoker.default.example.com/allow"
	@echo " * how does it work? ...."
	@echo "config_dump > | grep relation"
	@echo
	@echo "skaffold delete -n kjell # make undeploy"
	@echo "kubectl delete -f ./kube/kustomize/invoker-pod.yaml"
	@echo "kubectl delete -f /Users/emayssat/workspaces/github.com/jpmoc/istio-knative-primer.git/in/invoker--kservice.yaml"
	@echo "kubectl get pods,ksvc -A"

view_pods:
	kubectl get po -n $(KCL_NAMESPACE_NAME)
