#!/bin/bash
#default setup for mac and linux, builds on local minikube, not on A2

echo "Starting default Minikube..."
minikube start --driver=docker --memory=5600MB --cpus=3 --bootstrapper=kubeadm
minikube addons enable ingress

echo "Setting Docker environment for Minikube..."
eval $(minikube docker-env)

echo "Building Docker images..."
docker build --no-cache -t sms-checker-app:latest ../app
docker build --no-cache -t sms-model-service:latest ../model-service

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
  --set secret.SMTP_PASSWORD=mypassword \
  --set kube-prometheus-stack.prometheus.enabled=false \
  --set kube-prometheus-stack.grafana.enabled=false

echo "Removing conflicting datasource configurations..."
kubectl delete configmap sms-checker-monitoring-grafana-datasource --namespace default --ignore-not-found=true

echo "Reloading Grafana..."
kubectl delete pod -l app.kubernetes.io/name=grafana

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
