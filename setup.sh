#!/bin/bash
#default setup for mac and linux, builds on local minikube, not on A2

echo "Starting default Minikube..."
minikube start --driver=docker --memory=5600MB --cpus=3 --bootstrapper=kubeadm
minikube addons enable ingress

echo "Setting Docker environment for Minikube..."
eval $(minikube docker-env)

echo "Building Docker images..."
docker build -t sms-model-service:latest -f ../model-service/Dockerfile ../model-service
docker build -t sms-checker-app:latest -f ../app/Dockerfile ../app

# #i did not need to load images into minikube w newprofile on my mac, but if you do, uncomment below
# echo "Loading images into Minikube..."
# minikube image load sms-model-service:latest
# minikube image load sms-checker-app:latest

echo "Installing Istio..."
istioctl install --set profile=default -y

kubectl apply -f istio-system/gateway.yaml


echo "Mounting shared folder..."
nohup minikube mount ../model-service/output:/model-service/output > /tmp/minikube-mount.log 2>&1 & 

echo "install prometheus"
helm repo add prom-repo https://prometheus-community.github.io/helm-charts
helm install myprom prom-repo/kube-prometheus-stack

echo "Building Helm dependencies..."
helm dependency build ./sms-checker-chart

echo "Deploying Helm chart..."
helm upgrade --install sms-checker ./sms-checker-chart \
  --set secret.SMTP_USER=myuser \
  --set secret.SMTP_PASSWORD=mypassword


#test functionality
echo "helm list:"
helm list

echo "Starting a 30 second wait to ensure pods are running...... "; sleep 30; echo "Wait finished!"

echo "Waiting for pods to be ready..."
kubectl get pods

echo "Waiting for svc to be ready..."
kubectl get svc 

echo "Waiting for pvc to be ready..."
kubectl get pvc

echo "Waiting for pv to be ready..."
kubectl get pv


echo "Checking Istio resources..."
kubectl get gateway                            

kubectl get virtualservice                     

kubectl get destinationrule
