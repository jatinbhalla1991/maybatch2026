# AWS Console Access to EKS - aws-auth ConfigMap Guide

## Problem
Pods and namespace details are not visible in AWS Console even though they exist in the cluster.

## Root Cause
The IAM user/role viewing the AWS Console needs to be:
1. **Mapped in aws-auth ConfigMap** (Kubernetes RBAC)
2. **Have IAM permissions** to view EKS resources (AWS IAM policy)

## Solution

### Step 1: Identify Your AWS Console User/Role ARN

```bash
# Get your current AWS identity
aws sts get-caller-identity

# Output example:
# {
#     "UserId": "AIDAZZZZZZZZZZZZZZZZ",
#     "Account": "025044154120",
#     "Arn": "arn:aws:iam::025044154120:user/your-username"
# }
```

Copy the ARN value.

### Step 2: Update aws-auth ConfigMap

Edit the ConfigMap to add your user:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Or apply a patch:

```bash
# If adding a user
kubectl patch configmap aws-auth -n kube-system --type merge -p '{
  "data": {
    "mapUsers": "- userarn: arn:aws:iam::025044154120:user/YOUR-USERNAME\n  username: YOUR-USERNAME\n  groups:\n  - system:masters"
  }
}'
```

### Current aws-auth ConfigMap Format

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::025044154120:role/demo-eks-cluster1-node-group-role
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
  
  mapUsers: |
    - userarn: arn:aws:iam::025044154120:user/jatin
      username: jatin
      groups:
      - system:masters
    - userarn: arn:aws:iam::025044154120:root
      username: root-admin
      groups:
      - system:masters
```

### Step 3: Add More Users/Roles (Examples)

#### Example 1: Add Another IAM User

```bash
kubectl edit configmap aws-auth -n kube-system
```

Add to `mapUsers`:
```yaml
  mapUsers: |
    - userarn: arn:aws:iam::025044154120:user/jatin
      username: jatin
      groups:
      - system:masters
    - userarn: arn:aws:iam::025044154120:root
      username: root-admin
      groups:
      - system:masters
    - userarn: arn:aws:iam::025044154120:user/new-console-user
      username: new-console-user
      groups:
      - system:masters
```

#### Example 2: Add An IAM Role

```yaml
  mapRoles: |
    - rolearn: arn:aws:iam::025044154120:role/demo-eks-cluster1-node-group-role
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
    - rolearn: arn:aws:iam::025044154120:role/console-role
      username: console-user
      groups:
      - system:masters
```

#### Example 3: Add With Limited Permissions (View-Only)

```yaml
  mapUsers: |
    - userarn: arn:aws:iam::025044154120:user/read-only-user
      username: read-only-user
      groups:
      - view-only
```

Then create a read-only ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-only
rules:
- apiGroups: [""]
  resources: ["pods", "services", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch"]
```

### Step 4: Apply AWS IAM Permissions

The user also needs IAM permissions to VIEW EKS in AWS Console. Attach this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:ListNodegroups",
        "eks:DescribeNodegroup",
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 5: Verify Access

```bash
# Check your current identity is in the ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml | grep your-username

# Verify you can view pods
kubectl get pods -n html-app

# Verify you can view all resources
kubectl get all -n html-app
```

## Common Issues & Solutions

### Issue 1: "error: You must be logged in to the server"

**Solution:** 
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name demo-eks-cluster1

# Or with specific profile
aws eks update-kubeconfig --region us-east-1 --name demo-eks-cluster1 --profile your-profile
```

### Issue 2: "Forbidden" error when trying to view pods

**Solution:** Check aws-auth ConfigMap and ensure your user/role is mapped with proper groups.

### Issue 3: AWS Console shows "No Pods" but kubectl shows pods

**Possible Causes:**
1. Console user/role not in aws-auth ConfigMap ← **Most Common**
2. IAM permissions missing (eks:DescribeCluster, etc.)
3. Viewing wrong namespace
4. Console cache not refreshed

**Solution:**
1. Add user to aws-auth ConfigMap ✓
2. Attach IAM policy above ✓
3. Verify namespace selection in console ✓
4. Hard refresh browser (Ctrl+Shift+R) ✓

## Your Current Setup

**Account ID:** 025044154120  
**Cluster:** demo-eks-cluster1  
**Region:** us-east-1  

**Current Users in aws-auth:**
- jatin (system:masters) ✅
- root (system:masters) ✅

**To Add Your AWS Console User:**

1. Get your ARN:
   ```bash
   aws sts get-caller-identity
   ```

2. Edit ConfigMap:
   ```bash
   kubectl edit configmap aws-auth -n kube-system
   ```

3. Add your user to mapUsers section

4. Save and exit

5. Refresh AWS Console browser

## Complete Example - Updated ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::025044154120:role/demo-eks-cluster1-node-group-role
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
  
  mapUsers: |
    - userarn: arn:aws:iam::025044154120:user/jatin
      username: jatin
      groups:
      - system:masters
    - userarn: arn:aws:iam::025044154120:root
      username: root-admin
      groups:
      - system:masters
    - userarn: arn:aws:iam::025044154120:user/console-user
      username: console-user
      groups:
      - system:masters
```

## Quick Reference

| What You Want | Action |
|---|---|
| View EKS console | Add user to aws-auth ConfigMap |
| See pods in console | Verify aws-auth + IAM permissions |
| Give read-only access | Map to `view-only` group + ClusterRole |
| Remove user access | Remove from aws-auth ConfigMap |

## Next Steps

1. ✅ Add console user to aws-auth
2. ✅ Verify IAM permissions
3. ✅ Refresh AWS console
4. ✅ Check Resources → Workloads → Pods
5. ✅ Select `html-app` namespace to see your pods
