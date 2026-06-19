# Complete Deployment Guide - Java App + Prometheus + Grafana

## Current Java Application Status

Your Java application in `javasample/HelloWorld.java`:
- ✅ Runs HTTP server on port 8080
- ✅ Serves HTML interface
- ✅ Has `/health` endpoint for health checks
- ✅ Has `/metrics` endpoint ready for Prometheus metrics

## Enhancement Plan

To enable monitoring on Grafana, we need to:
1. **Enhance Java app** with Prometheus metrics counters
2. **Deploy Java app** to Kubernetes with Prometheus annotations
3. **Deploy Prometheus** to scrape metrics from Java app
4. **Deploy Grafana** to visualize the metrics

## Deployment Steps

### Step 1: Build and Deploy Java Application

```bash
cd javasample

# Build Docker image
docker build -t java-sample:1.0 .

# For local Kubernetes clusters (minikube/kind/docker-desktop)
# Image is automatically available

# For cloud registries (AWS ECR)
docker tag java-sample:1.0 <account-id>.dkr.ecr.us-east-1.amazonaws.com/java-sample:1.0
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/java-sample:1.0
```

### Step 2: Deploy Prometheus

```bash
cd docker

# Deploy Prometheus (monitoring namespace)
kubectl apply -f prometheus-stack.yaml

# Verify
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Step 3: Deploy Grafana

```bash
# Deploy Grafana
kubectl apply -f grafana-stack.yaml

# Verify
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Step 4: Deploy Java Application with Metrics

```bash
# Deploy Java app
kubectl apply -f java-app-deployment.yaml

# Verify
kubectl get pods -n java-app
kubectl get svc -n java-app
```

## Access Your Services

### Java Application
```bash
# Get LoadBalancer IP
kubectl get svc java-app-loadbalancer -n java-app

# Access
http://<EXTERNAL_IP>
http://<EXTERNAL_IP>/health
http://<EXTERNAL_IP>/metrics  (Prometheus metrics)
```

### Prometheus
```bash
# Port forward
kubectl port-forward svc/prometheus 9090:9090 -n monitoring

# Access
http://localhost:9090
```

### Grafana
```bash
# Get LoadBalancer IP
kubectl get svc grafana-loadbalancer -n monitoring

# Or port forward
kubectl port-forward svc/grafana-loadbalancer 3000:80 -n monitoring

# Access
http://localhost:3000
# Username: admin
# Password: admin123
```

## Grafana Setup

### 1. Add Prometheus Datasource
- Go to: Configuration → Data Sources
- Add Data Source → Prometheus
- URL: http://prometheus:9090
- Save

### 2. Create Dashboard
- Go to: Dashboards → Create → New Dashboard
- Add panels for:
  - Java app requests total
  - Success rate
  - Error rate
  - Memory usage
  - Uptime

### 3. Import Pre-built Dashboards
- Go to: Dashboards → Import
- Use dashboard ID: 1621 (Java application dashboard)
- Select Prometheus datasource

## Available Metrics

Your Java app exposes:
```
java_app_requests_total        - Total requests count
java_app_requests_success      - Successful requests count
java_app_requests_errors       - Failed requests count
java_app_health_checks         - Health check calls count
java_app_uptime_ms             - Application uptime in ms
java_memory_used               - Memory used in bytes
java_memory_max                - Maximum memory in bytes
java_memory_usage_percent      - Memory usage percentage
```

## Monitoring Setup

### Prometheus automatically scrapes:
1. Java app metrics (via prometheus.io/scrape annotation)
2. Kubernetes API server metrics
3. Kubernetes node metrics
4. Kubernetes pod metrics

### Grafana visualizes:
- Request rate (RPS)
- Error rate
- Response time
- Memory usage
- CPU usage
- Uptime

## Complete Deployment Script

```bash
#!/bin/bash

# Step 1: Build Java image
cd ~/Documents/maybatch2026/javasample
docker build -t java-sample:1.0 .

# For local cluster, load image
# minikube image load java-sample:1.0
# OR
# kind load docker-image java-sample:1.0

# Step 2: Deploy monitoring stack
cd ~/Documents/maybatch2026/docker
kubectl apply -f prometheus-stack.yaml
kubectl apply -f grafana-stack.yaml

# Step 3: Deploy Java application
kubectl apply -f java-app-deployment.yaml

# Step 4: Wait for deployments
kubectl rollout status deployment/java-app -n java-app
kubectl rollout status deployment/prometheus -n monitoring
kubectl rollout status deployment/grafana -n monitoring

# Step 5: Port forward Grafana
kubectl port-forward svc/grafana-loadbalancer 3000:80 -n monitoring &

echo "✅ All services deployed!"
echo "Grafana: http://localhost:3000"
echo "Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n monitoring"
```

## Verify Everything is Running

```bash
# Check all pods
kubectl get pods -n java-app
kubectl get pods -n monitoring

# Check services
kubectl get svc -n java-app
kubectl get svc -n monitoring

# Check metrics endpoint
kubectl exec -it <java-app-pod> -n java-app -- curl http://localhost:8080/metrics

# Check Prometheus targets
kubectl exec -it <prometheus-pod> -n monitoring -- curl http://localhost:9090/api/v1/targets
```

## Troubleshooting

### Prometheus not scraping Java app
```bash
# Check prometheus config
kubectl logs -f deployment/prometheus -n monitoring

# Verify Java app has correct annotations:
kubectl describe pod <java-app-pod> -n java-app | grep prometheus
```

### Grafana can't connect to Prometheus
```bash
# Check connectivity
kubectl exec -it <grafana-pod> -n monitoring -- wget http://prometheus:9090
```

### No metrics data in Grafana
- Wait 1-2 minutes for Prometheus to scrape metrics
- Check Prometheus targets: http://localhost:9090/targets
- Verify Java app has annotation: prometheus.io/scrape: "true"

## Next Steps

1. ✅ Build Java image with metrics endpoint
2. ✅ Deploy Prometheus with Java app target
3. ✅ Deploy Grafana connected to Prometheus
4. ✅ Create monitoring dashboard
5. Generate traffic to Java app to see metrics
6. Create alerts in Prometheus
7. Configure alert notifications in Grafana
