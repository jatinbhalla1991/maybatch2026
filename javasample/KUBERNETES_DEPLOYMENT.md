# Kubernetes Deployment Guide

This guide explains how to deploy the Java Sample Application to a Kubernetes cluster.

## Prerequisites
- Kubernetes cluster (v1.20+)
- `kubectl` CLI installed and configured
- Docker image pushed to a container registry or available locally

## Kubernetes Manifest Contents

The `kubernetes-manifest.yaml` file includes:

1. **Namespace** - `java-app` namespace for resource isolation
2. **ConfigMap** - Application configuration
3. **PersistentVolumeClaims** - Storage for logs and data
4. **Deployment** - 3 replicas with rolling updates
5. **LoadBalancer Service** - External access on port 80
6. **ClusterIP Service** - Internal service communication
7. **ServiceAccount** - Security and RBAC
8. **Role & RoleBinding** - RBAC permissions
9. **HorizontalPodAutoscaler** - Auto-scaling based on CPU/Memory
10. **NetworkPolicy** - Security policies

## Deployment Steps

### Step 1: Build and Push Docker Image (if using container registry)

```bash
# Build the image
docker build -t your-registry/java-sample:1.0 .

# Push to registry
docker push your-registry/java-sample:1.0
```

If using local image, update the `imagePullPolicy` to `IfNotPresent` in the deployment (already done).

### Step 2: Apply the Kubernetes Manifest

```bash
# Apply all resources
kubectl apply -f kubernetes-manifest.yaml

# Verify deployment
kubectl get all -n java-app
```

### Step 3: Monitor the Deployment

```bash
# Check deployment status
kubectl get deployment -n java-app

# Check pods
kubectl get pods -n java-app

# View pod logs
kubectl logs -f deployment/java-app -n java-app

# Watch the deployment
kubectl rollout status deployment/java-app -n java-app
```

### Step 4: Access the Application

#### Using LoadBalancer Service:

```bash
# Get the external IP (may take 1-2 minutes)
kubectl get svc java-app-loadbalancer -n java-app

# Access the application
# For cloud providers: http://<EXTERNAL-IP>
# For local clusters (minikube): kubectl port-forward svc/java-app-loadbalancer 80:80 -n java-app
# Then access: http://localhost
```

#### Using Port Forwarding (for local testing):

```bash
# Forward port 8080 from your machine to the service
kubectl port-forward svc/java-app-internal 8080:8080 -n java-app

# Access: http://localhost:8080
# Health check: http://localhost:8080/health
```

#### Using kubectl proxy:

```bash
kubectl proxy
# Access through: http://localhost:8001/api/v1/namespaces/java-app/services/java-app-internal:8080/proxy/
```

## Useful Commands

### Debugging

```bash
# Describe deployment
kubectl describe deployment java-app -n java-app

# Describe a specific pod
kubectl describe pod <pod-name> -n java-app

# View events
kubectl get events -n java-app --sort-by='.lastTimestamp'

# Access pod shell (if applicable)
kubectl exec -it <pod-name> -n java-app -- /bin/sh
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment java-app --replicas=5 -n java-app

# Check HPA status
kubectl get hpa -n java-app
kubectl describe hpa java-app-hpa -n java-app
```

### Storage

```bash
# Check PersistentVolumeClaims
kubectl get pvc -n java-app

# Check logs
kubectl logs <pod-name> -n java-app

# Access logs from PV (mount to another pod if needed)
```

### Updates & Rollouts

```bash
# Update image
kubectl set image deployment/java-app java-app=new-image:tag -n java-app

# Check rollout history
kubectl rollout history deployment/java-app -n java-app

# Rollback to previous version
kubectl rollout undo deployment/java-app -n java-app
```

### Cleanup

```bash
# Delete all resources
kubectl delete -f kubernetes-manifest.yaml

# Delete specific resource
kubectl delete deployment java-app -n java-app

# Delete namespace (deletes all resources in it)
kubectl delete namespace java-app
```

## Configuration

### Change Replicas
Edit `kubernetes-manifest.yaml` and change the `replicas` field in the Deployment spec.

### Change Image
Update the `image` field in the Deployment container spec.

### Change Port Mapping
Modify the `port` and `targetPort` in the LoadBalancer service section.

### Scale Limits
Adjust `minReplicas` and `maxReplicas` in the HorizontalPodAutoscaler section.

### Resource Limits
Modify `resources.requests` and `resources.limits` in the container spec.

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n java-app
kubectl logs <pod-name> -n java-app
```

### LoadBalancer not getting external IP
- Check if your cluster supports LoadBalancer (cloud providers do, local clusters may not)
- For local clusters use NodePort or port-forward instead

### PersistentVolume not binding
- Ensure storage class exists: `kubectl get storageclass`
- Check PV availability: `kubectl get pv`

### Service unreachable
- Check if service is created: `kubectl get svc -n java-app`
- Verify pods are running: `kubectl get pods -n java-app`
- Check network policies: `kubectl get networkpolicy -n java-app`

## Performance Tuning

1. **Adjust Resource Requests/Limits** - Based on your workload
2. **Configure HPA** - Tune metrics and thresholds
3. **Enable Pod Disruption Budgets** - For high availability
4. **Use Node Affinity** - For better pod distribution

## Security Notes

- Non-root user (UID 1001) runs the application
- Read-only root filesystem (can be enabled if needed)
- Network policies restrict traffic
- RBAC configured with minimal permissions
- Service account is namespace-scoped

## Next Steps

1. Configure Ingress for HTTP(S) routing
2. Set up Monitoring with Prometheus/Grafana
3. Configure Logging with ELK/Loki
4. Set up CI/CD for automated deployments
5. Implement backup strategy for PersistentVolumes
