#!/bin/bash

# Kubernetes Deployment Script for Docker HTML Application
# This script automates the deployment of the HTML Docker image to Kubernetes

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="html-app"
IMAGE_TAG="latest"
NAMESPACE="html-app"
MANIFEST_TYPE="${1:-simple}"  # simple or full

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker HTML Application - Kubernetes Deployment${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi
print_status "kubectl found"

if ! command -v docker &> /dev/null; then
    print_error "docker is not installed"
    exit 1
fi
print_status "docker found"

# Check kubernetes connection
print_info "Checking Kubernetes cluster connection..."
if kubectl cluster-info &> /dev/null; then
    print_status "Connected to Kubernetes cluster"
else
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Build Docker image
print_info "Building Docker image..."
if docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .; then
    print_status "Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Check if running on local cluster (minikube, kind, docker-desktop)
KUBE_CONTEXT=$(kubectl config current-context)
print_info "Current Kubernetes context: $KUBE_CONTEXT"

# For local clusters, load the image
if [[ "$KUBE_CONTEXT" == *"minikube"* ]]; then
    print_info "Loading image into Minikube..."
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_status "Image loaded into Minikube"
elif [[ "$KUBE_CONTEXT" == *"kind"* ]]; then
    print_info "Loading image into Kind..."
    kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG}
    print_status "Image loaded into Kind"
elif [[ "$KUBE_CONTEXT" == *"docker"* ]] || [[ "$KUBE_CONTEXT" == *"docker-desktop"* ]]; then
    print_status "Using Docker Desktop - image is automatically available"
else
    print_warning "Unknown cluster type - assuming image is available in registry"
fi

# Choose manifest
if [ "$MANIFEST_TYPE" = "full" ]; then
    MANIFEST_FILE="kubernetes-manifest.yaml"
    print_info "Using full manifest: $MANIFEST_FILE"
else
    MANIFEST_FILE="kubernetes-manifest-simple.yaml"
    print_info "Using simple manifest: $MANIFEST_FILE"
fi

# Check if manifest file exists
if [ ! -f "$MANIFEST_FILE" ]; then
    print_error "Manifest file not found: $MANIFEST_FILE"
    exit 1
fi
print_status "Manifest file found"

# Apply Kubernetes manifest
print_info "Deploying application to Kubernetes..."
if kubectl apply -f "$MANIFEST_FILE"; then
    print_status "Manifest applied successfully"
else
    print_error "Failed to apply manifest"
    exit 1
fi

# Wait for deployment to be ready
print_info "Waiting for deployment to be ready (this may take a minute)..."
if kubectl rollout status deployment/html-app -n $NAMESPACE --timeout=5m; then
    print_status "Deployment is ready"
else
    print_warning "Deployment rollout timeout - checking status"
fi

# Get service information
print_info "Retrieving service information..."
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Display services
kubectl get svc -n $NAMESPACE

echo ""
print_info "Accessing your application:\n"

# LoadBalancer
LB_IP=$(kubectl get svc html-app-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")
if [ "$LB_IP" = "PENDING" ] || [ -z "$LB_IP" ]; then
    print_warning "LoadBalancer IP is still pending (this is normal for local clusters)"
    echo -e "  ${YELLOW}Option 1: Use port-forward${NC}"
    echo -e "    ${YELLOW}kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app${NC}"
    echo -e "    ${YELLOW}Then access: http://localhost:8080${NC}\n"
else
    print_status "LoadBalancer Service: http://$LB_IP"
    echo ""
fi

echo -e "  ${BLUE}Option 2: Use port-forward${NC}"
echo -e "    kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app"
echo -e "    Access: http://localhost:8080\n"

echo -e "  ${BLUE}Option 3: Use NodePort Service${NC}"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi
if [ -n "$NODE_IP" ]; then
    echo -e "    Access: http://$NODE_IP:30080\n"
fi

# Deployment status
echo -e "${BLUE}Deployment Status:${NC}\n"
kubectl get deployment -n $NAMESPACE
echo ""
kubectl get pods -n $NAMESPACE
echo ""

# Useful commands
echo -e "${BLUE}Useful Commands:${NC}\n"
echo "View logs:"
echo "  kubectl logs -f deployment/html-app -n $NAMESPACE"
echo ""
echo "Scale deployment:"
echo "  kubectl scale deployment html-app --replicas=5 -n $NAMESPACE"
echo ""
echo "Watch deployment:"
echo "  kubectl rollout status deployment/html-app -n $NAMESPACE"
echo ""
echo "Access pod shell:"
echo "  kubectl exec -it <pod-name> -n $NAMESPACE -- /bin/sh"
echo ""
echo "Delete deployment:"
echo "  kubectl delete -f $MANIFEST_FILE"
echo ""

print_status "Deployment completed successfully!"
