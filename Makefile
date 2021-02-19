-include $(shell curl -sSL -o .build-harness "https://raw.githubusercontent.com/russelltsherman/build-harness/main/templates/Makefile.build-harness"; echo .build-harness)

.DEFAULT_GOAL :=

## initialize project and load dependencies
bootstrap: init brew direnv manifest 
.PHONY: bootstrap

## configure and start minikube instance
minikube: 
	minikube config set kubernetes-version 1.19.8
	minikube config set bootstrapper kubeadm
	minikube config set container-runtime docker
	minikube config set vm-driver virtualbox
	minikube config set cpus 6
	minikube config set memory 16384
	minikube start
.PHONY: minikube
