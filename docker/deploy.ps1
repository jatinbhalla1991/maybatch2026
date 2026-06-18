# Kubernetes Deployment Script for Docker HTML Application - PowerShell Version
# This script automates the deployment of the HTML Docker image to Kubernetes

$ErrorActionPreference = "Stop"

# Configuration
$ImageName = "html-app"
$ImageTag = "latest"
$Namespace = "html-app"
$ManifestType = if ($args[0]) { $args[0] } else { "simple" }

# Helper functions
function Write-Status {
    Write-Host "[✓] $args" -ForegroundColor Green
}

function Write-Info {
    Write-Host "[i] $args" -ForegroundColor Cyan
}

function Write-Warning {
    Write-Host "[!] $args" -ForegroundColor Yellow
}

function Write-Error-Custom {
    Write-Host "[✗] $args" -ForegroundColor Red
}

# Print header
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker HTML Application - Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Info "Checking prerequisites..."

try {
    $null = kubectl version --client
    Write-Status "kubectl found"
} catch {
    Write-Error-Custom "kubectl is not installed or not in PATH"
    exit 1
}

try {
    $null = docker version
    Write-Status "docker found"
} catch {
    Write-Error-Custom "docker is not installed or not in PATH"
    exit 1
}

# Check kubernetes connection
Write-Info "Checking Kubernetes cluster connection..."
try {
    $null = kubectl cluster-info 2>$null
    Write-Status "Connected to Kubernetes cluster"
} catch {
    Write-Error-Custom "Cannot connect to Kubernetes cluster"
    exit 1
}

# Build Docker image
Write-Info "Building Docker image..."
try {
    docker build -t "$($ImageName):$($ImageTag)" .
    Write-Status "Docker image built successfully: $($ImageName):$($ImageTag)"
} catch {
    Write-Error-Custom "Failed to build Docker image"
    exit 1
}

# Check Kubernetes context
$KubeContext = kubectl config current-context
Write-Info "Current Kubernetes context: $KubeContext"

# Load image into local cluster if needed
if ($KubeContext -like "*minikube*") {
    Write-Info "Loading image into Minikube..."
    minikube image load "$($ImageName):$($ImageTag)"
    Write-Status "Image loaded into Minikube"
} elseif ($KubeContext -like "*kind*") {
    Write-Info "Loading image into Kind..."
    kind load docker-image "$($ImageName):$($ImageTag)"
    Write-Status "Image loaded into Kind"
} elseif ($KubeContext -like "*docker*") {
    Write-Status "Using Docker Desktop - image is automatically available"
} else {
    Write-Warning "Unknown cluster type - assuming image is available in registry"
}

# Choose manifest
if ($ManifestType -eq "full") {
    $ManifestFile = "kubernetes-manifest.yaml"
    Write-Info "Using full manifest: $ManifestFile"
} else {
    $ManifestFile = "kubernetes-manifest-simple.yaml"
    Write-Info "Using simple manifest: $ManifestFile"
}

# Check manifest exists
if (!(Test-Path $ManifestFile)) {
    Write-Error-Custom "Manifest file not found: $ManifestFile"
    exit 1
}
Write-Status "Manifest file found"

# Apply manifest
Write-Info "Deploying application to Kubernetes..."
try {
    kubectl apply -f $ManifestFile
    Write-Status "Manifest applied successfully"
} catch {
    Write-Error-Custom "Failed to apply manifest"
    exit 1
}

# Wait for deployment
Write-Info "Waiting for deployment to be ready (this may take a minute)..."
try {
    kubectl rollout status deployment/html-app -n $Namespace --timeout=5m
    Write-Status "Deployment is ready"
} catch {
    Write-Warning "Deployment rollout timeout - checking status"
}

# Get service information
Write-Info "Retrieving service information..."
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

kubectl get svc -n $Namespace

Write-Host ""
Write-Info "Accessing your application:`n"

# Get LoadBalancer IP
$LB_IP = kubectl get svc html-app-loadbalancer -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$LB_Hostname = kubectl get svc html-app-loadbalancer -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

if ($LB_IP -or $LB_Hostname) {
    $Endpoint = if ($LB_IP) { $LB_IP } else { $LB_Hostname }
    Write-Status "LoadBalancer Service: http://$Endpoint"
    Write-Host ""
} else {
    Write-Warning "LoadBalancer IP is still pending (this is normal for local clusters)"
    Write-Host "  Option 1: Use port-forward"
    Write-Host "    kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app"
    Write-Host "    Then access: http://localhost:8080`n" -ForegroundColor Yellow
}

Write-Host "  Option 2: Use port-forward"
Write-Host "    kubectl port-forward svc/html-app-loadbalancer 8080:80 -n html-app"
Write-Host "    Access: http://localhost:8080`n" -ForegroundColor Cyan

Write-Host "  Option 3: Use NodePort Service"
$NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>$null
if (!$NodeIP) {
    $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>$null
}
if ($NodeIP) {
    Write-Host "    Access: http://$NodeIP:30080`n" -ForegroundColor Cyan
}

# Deployment status
Write-Host "Deployment Status:`n" -ForegroundColor Cyan
kubectl get deployment -n $Namespace
Write-Host ""
kubectl get pods -n $Namespace
Write-Host ""

# Useful commands
Write-Host "Useful Commands:`n" -ForegroundColor Cyan
Write-Host "View logs:"
Write-Host "  kubectl logs -f deployment/html-app -n $Namespace"
Write-Host ""
Write-Host "Scale deployment:"
Write-Host "  kubectl scale deployment html-app --replicas=5 -n $Namespace"
Write-Host ""
Write-Host "Watch deployment:"
Write-Host "  kubectl rollout status deployment/html-app -n $Namespace"
Write-Host ""
Write-Host "Access pod shell:"
Write-Host "  kubectl exec -it <pod-name> -n $Namespace -- /bin/sh"
Write-Host ""
Write-Host "Delete deployment:"
Write-Host "  kubectl delete -f $ManifestFile"
Write-Host ""

Write-Status "Deployment completed successfully!"
