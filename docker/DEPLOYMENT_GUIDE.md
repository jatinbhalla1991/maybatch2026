# Kubernetes Deployment Guide - Docker HTML Application

## Overview

This guide explains how to deploy the HTML Docker image to Kubernetes using the provided manifests.

## Prerequisites

1. **Kubernetes cluster** (v1.20+) running and configured
2. **kubectl** CLI installed and authenticated
3. **Docker image** built and available:
   - Either: Pushed to container registry (DockerHub, ECR, ACR, GCR)
   - Or: Available locally on cluster nodes

## Step 1: Build the Docker Image

```bash
cd docker/

# Build the image
docker build -t html-app:latest .

# Verify the build
docker images | grep html-app
```

## Step 2: Make Image Available to Kubernetes

### Option A: Push to Container Registry (Recommended for Production)

```bash
# DockerHub
docker tag html-app:latest your-username/html-app:latest
docker push your-username/html-app:latest

# Then update manifests: change image from 'html-app:latest' to 'your-username/html-app:latest'
# And change imagePullPolicy from 'IfNotPresent' to 'Always'
```

### Option B: Use Local Image (For Local Clusters)

```bash
# For Docker Desktop, minikube, kind - image is automatically available
# No additional steps needed
```

### Option C: Load Image into Minikube/Kind

```bash
# For Minikube
minikube image load html-app:latest

# For Kind
kind load docker-image html-app:latest --name your-cluster-name
```

## Step 3: Deploy to Kubernetes

### Quick Deployment (Simple Manifest)

```bash
# Apply simple manifest (2 replicas, LoadBalancer service)
kubectl apply -f kubernetes-manifest-simple.yaml

# Verify deployment
kubectl get all -n html-app
```

### Full Production Deployment

```bash
# Apply full manifest (3 replicas, multiple services, HPA, health checks)
kubectl apply -f kubernetes-manifest.yaml

# Verify deployment
kubectl get all -n html-app
```

## Step 4: Access the Application

### Via LoadBalancer Service (External Access)

```bash
# Get the external IP (wait 1-2 minutes)
kubectl get svc html-app-loadbalancer -n html-app

# Output will show:
# NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)
# html-app-loadbalancer      LoadBalancer   10.x.x.x      203.0.113.1     80:xxxxx/TCP

# Access: http://203.0.113.1
```

### Via Port Forwarding (Local/Testing)

```bash
# Forward LoadBalancer
kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app

# Access: http://localhost:8080
```

### Via NodePort Service

```bash
# Get node IP
kubectl get nodes -o wide

# Access: http://<NODE_IP>:30080
```

### Via Kubectl Proxy

```bash
kubectl proxy

# Access: http://localhost:8001/api/v1/namespaces/html-app/services/http:html-app-internal:80/proxy/
```

## Manifest Components

### kubernetes-manifest.yaml (Full Version)

| Component | Description |
|---|---|
| **Namespace** | `html-app` - Isolated namespace |
| **Deployment** | 3 replicas, rolling updates |
| **LoadBalancer** | External access on port 80 |
| **ClusterIP** | Internal access on port 80 |
| **NodePort** | Node access on port 30080 |
| **HPA** | Auto-scales 3-10 replicas based on CPU/Memory |
| **Health Checks** | Liveness & Readiness probes |

### kubernetes-manifest-simple.yaml (Simple Version)

| Component | Description |
|---|---|
| **Namespace** | `html-app` |
| **Deployment** | 2 replicas |
| **LoadBalancer** | External access on port 80 |
| **ClusterIP** | Internal access on port 80 |
| **Health Checks** | Liveness & Readiness probes |

## Common Commands

### Monitor Deployment

```bash
# Check deployment status
kubectl get deployment -n html-app
kubectl describe deployment html-app -n html-app

# Check pods
kubectl get pods -n html-app -o wide
kubectl describe pod <pod-name> -n html-app

# View logs
kubectl logs -f deployment/html-app -n html-app
kubectl logs <pod-name> -n html-app

# Watch rollout progress
kubectl rollout status deployment/html-app -n html-app
```

### Check Services

```bash
# List all services
kubectl get svc -n html-app

# Check LoadBalancer details
kubectl describe svc html-app-loadbalancer -n html-app

# View endpoints
kubectl get endpoints -n html-app
```

### Scale Application

```bash
# Manual scaling
kubectl scale deployment html-app --replicas=5 -n html-app

# Check HPA status (full manifest only)
kubectl get hpa -n html-app
kubectl describe hpa html-app-hpa -n html-app
```

### Test Connectivity

```bash
# Get into a pod and test
kubectl exec -it <pod-name> -n html-app -- /bin/sh

# From pod, test with curl
curl http://localhost/
curl http://html-app-internal/
```

### Update Application

```bash
# Rebuild Docker image
docker build -t html-app:v2 .
docker push your-registry/html-app:v2

# Update deployment with new image
kubectl set image deployment/html-app html-app=html-app:v2 -n html-app

# Watch the rollout
kubectl rollout status deployment/html-app -n html-app

# Rollback if needed
kubectl rollout undo deployment/html-app -n html-app
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n html-app

# Describe pod for error details
kubectl describe pod <pod-name> -n html-app

# View logs
kubectl logs <pod-name> -n html-app
```

### LoadBalancer shows `<pending>`

This is normal if:
- Using local cluster (minikube, kind, Docker Desktop)
- Cloud provider LoadBalancer is slow to provision

**Solutions:**
- Use NodePort instead: `kubectl get svc html-app-nodeport -n html-app`
- Use port-forward: `kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app`
- Wait longer (up to 5 minutes for cloud providers)

### Application not responding

```bash
# Check if pods are running and ready
kubectl get pods -n html-app

# Check service endpoints
kubectl get endpoints html-app-loadbalancer -n html-app

# Check pod logs for errors
kubectl logs <pod-name> -n html-app

# Test from inside cluster
kubectl run -it debug --image=alpine --restart=Never -n html-app -- sh
# Inside pod: wget http://html-app-internal/
```

### Image pull errors

```bash
# If using registry, check pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n html-app

# Update deployment to use imagePullSecrets:
# spec:
#   template:
#     spec:
#       imagePullSecrets:
#       - name: regcred
```

## Advanced Configuration

### Update Replicas

Edit the deployment:
```bash
kubectl edit deployment html-app -n html-app
# Change: replicas: 3 -> replicas: 5
```

### Change Service Port

Edit the service:
```bash
kubectl edit svc html-app-loadbalancer -n html-app
# Change port mappings
```

### Modify Resource Limits

Edit the deployment:
```bash
kubectl edit deployment html-app -n html-app
# Adjust resources:
#   requests:
#     memory: "128Mi"
#     cpu: "200m"
#   limits:
#     memory: "512Mi"
#     cpu: "1000m"
```

### Update HTML Content

If you need to change the HTML:

1. Update `index.html` in the docker folder
2. Rebuild the Docker image:
   ```bash
   docker build -t html-app:v2 .
   docker push your-registry/html-app:v2
   ```
3. Update the deployment:
   ```bash
   kubectl set image deployment/html-app html-app=html-app:v2 -n html-app
   ```

## Cleanup

```bash
# Delete deployment only
kubectl delete deployment html-app -n html-app

# Delete all resources in namespace
kubectl delete all -n html-app

# Delete entire namespace (removes all resources)
kubectl delete namespace html-app
```

## Performance Tuning

1. **Increase Replicas:** `kubectl scale deployment html-app --replicas=10 -n html-app`
2. **Adjust Resource Limits:** Edit deployment resources
3. **Monitor HPA:** `kubectl describe hpa html-app-hpa -n html-app`
4. **Use NodePort for high throughput:** Bypasses LoadBalancer

## Security Best Practices

1. **Use private container registry** for production
2. **Image scanning** - scan for vulnerabilities before deployment
3. **RBAC** - add ServiceAccount and Role if needed
4. **NetworkPolicy** - restrict traffic between pods
5. **Resource limits** - prevent resource exhaustion

## Next Steps

1. Set up Ingress for HTTP/HTTPS routing
2. Configure TLS certificates
3. Set up monitoring (Prometheus/Grafana)
4. Configure logging (ELK/Loki)
5. Implement horizontal pod autoscaling thresholds
6. Add persistent storage if needed
7. Set up backup strategy
