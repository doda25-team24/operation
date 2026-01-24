#!/bin/bash
# Script for Minikube np setup, issue that happened on the mac of one of the team members(Sara Cortez)
#builds on local minikube, not on A2


echo "Starting Minikube with profile 'np'..."
minikube start -p np --driver=docker --memory=5600MB --cpus=3 --bootstrapper=kubeadm
minikube -p np addons enable ingress

# run this every time you open a new terminal
echo "Setting Docker environment for Minikube..."
eval $(minikube -p np docker-env)

#i did not need to load images into minikube w np on my mac, but if you do, uncomment below
# echo "Loading images into Minikube..."
# minikube -p np image load sms-model-service:latest
# minikube -p np image load sms-checker-app:latest

echo "Building Docker images..."
docker build --no-cache -t sms-checker-app:latest ../app #-f ../model-service/Dockerfile ../model-service
docker build --no-cache -t sms-model-service:latest ../model-service #-f ../app/Dockerfile ../app


echo "Installing Istio..."
istioctl install --set profile=default -y

kubectl apply -f istio-system/gateway.yaml

echo "Mounting shared folder..."
nohup minikube  -p np mount ../model-service/output:/model-service/output > /tmp/minikube-mount.log 2>&1 & 
nohup sudo minikube tunnel -p np  > /tmp/tunnel.log 2>&1 & 

echo "install prometheus"
helm repo add prom-repo https://prometheus-community.github.io/helm-charts
helm repo update
helm install myprom prom-repo/kube-prometheus-stack --set grafana.enabled=true

echo "Building Helm dependencies..."
helm dependency build ./sms-checker-chart

echo "Waiting for Operator..."
sleep 10

echo "Deploying Helm chart..."
helm upgrade --install sms-checker ./sms-checker-chart \
  --set app.image.pullPolicy=IfNotPresent \
  --set model.image.pullPolicy=IfNotPresent \
  --set secret.SMTP_USER=myuser \
  --set secret.SMTP_PASSWORD=mypassword

#test functionality
echo "helm list:"
helm list

echo "Starting a 30 second wait to ensure pods are running...... "; sleep 30; echo "Wait finished!"

echo "Waiting for pods to be ready..."

kubectl --context=np get pods

echo "Waiting for svc to be ready..."
kubectl --context=np get svc 

echo "Waiting for pvc to be ready..."
kubectl --context=np get pvc

echo "Waiting for pv to be ready..."
kubectl --context=np get pv


echo "Checking Istio resources..."
kubectl get gateway                            

kubectl get virtualservice                     

kubectl get destinationrule
