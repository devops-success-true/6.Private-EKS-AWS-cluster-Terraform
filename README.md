# 🚀 6.Private-EKS-AWS-Cluster-Terraform

**Production-grade Private Amazon EKS cluster built with Terraform**  
Includes full OIDC integration, ArgoCD GitOps, load balancer controllers, IAM roles, autoscaling, observability, and secure networking.

---

## 🧭 Project Overview

This project provisions a **private Amazon EKS cluster** using Terraform — designed to reflect real production infrastructure.  
The cluster is **isolated within private subnets**, integrated with **AWS IAM OIDC**, **ArgoCD** for GitOps, **monitoring tools**, and **ALB ingress controller** for ingress management.

---

## 🏗️ Core Architecture

| Component | Purpose | Relationship |
|------------|----------|--------------|
| **VPC** | Base networking layer (public & private subnets across AZs) | Hosts all EKS networking components |
| **Private EKS Cluster** | Main Kubernetes control plane | Deployed inside private subnets, accessible via bastion or VPN |
| **OIDC Provider** | Integrates AWS IAM with Kubernetes | Enables fine-grained IAM Roles for Service Accounts (IRSA) |
| **Node Groups / Managed Nodes** | Worker nodes for pods | Registered to the EKS cluster within private subnets |
| **AWS ALB Controller** | Manages ingress via Application Load Balancer | Exposes Kubernetes services securely |
| **ArgoCD** | GitOps tool for CI/CD | Syncs apps from Git repositories into the cluster |
| **Cluster Autoscaler / Karpenter** | Autoscaling engine | Adjusts nodes dynamically based on workloads |
| **Monitoring Stack** | Prometheus, Grafana, CloudWatch | Observability for cluster metrics and logs |
| **Terraform Backend** | Remote S3 + DynamoDB | Stores Terraform state & lock files securely |

---

## 🔗 Relationships Between Components

```
Developers → Push manifests to GitHub Repo
              │
              ▼
        [ArgoCD Controller]
              │   (Watches Git)
              ▼
       [Kubernetes Cluster]
              │
              ├──> [EKS Control Plane (Private)]
              │         │
              │         ├──> OIDC Provider (IAM Auth for Service Accounts)
              │         ├──> ALB Ingress Controller (Ingress/Load Balancing)
              │         ├──> Cluster Autoscaler / Karpenter (Dynamic Scaling)
              │         └──> Prometheus + Grafana (Monitoring)
              │
              ▼
       [AWS Resources via Terraform]
         ├── VPC, Subnets, Security Groups
         ├── IAM Roles / Policies
         ├── S3 Remote Backend
         └── DynamoDB State Locking
```

All communication to AWS APIs happens via **VPC Interface Endpoints** — no Internet Gateway access required for control plane or worker nodes.

---

## 🧩 Terraform Module Breakdown

### 1️⃣ **Networking Module**
- Creates multi-AZ VPC with public and private subnets  
- Configures route tables, NAT gateways, and VPC endpoints  
- Provides networking IDs to other modules

### 2️⃣ **EKS Module**
- Deploys private EKS cluster (no public endpoint)  
- Associates IAM OIDC provider  
- Creates node groups within private subnets  
- Configures kubeconfig for local access via bastion host

### 3️⃣ **IAM / OIDC Module**
- Creates IAM roles for:
  - Cluster Autoscaler
  - ALB Controller
  - ArgoCD
  - EBS CSI Driver
- Uses `aws_iam_openid_connect_provider` for federated identity

### 4️⃣ **Controllers & Addons**
- **Metrics Server**
- **Cluster Autoscaler**
- **ALB Ingress Controller**
- **EBS CSI Driver**
- **Nginx Ingress (optional)**
- **Cert Manager**
- All deployed via **Helm releases** managed in Terraform

### 5️⃣ **GitOps (ArgoCD)**
- Deploys ArgoCD via Helm
- Configures repositories for app synchronization
- Automates manifest deployment from Git → Kubernetes

### 6️⃣ **Monitoring**
- Deploys Prometheus + Grafana stack
- Optional CloudWatch Container Insights integration
- Exposes dashboards via internal Ingress

---

## 🧰 Prerequisites

- Terraform >= 1.5  
- AWS CLI configured (`aws configure`)  
- IAM permissions for VPC, EKS, IAM, and S3  
- S3 bucket + DynamoDB table for Terraform remote backend  
- Git repository for ArgoCD sync

---

## 🪜 Deployment Steps

### 1. **Set up Backend**
```bash
aws s3api create-bucket --bucket tfstate-eks-cluster --region us-east-1
aws dynamodb create-table   --table-name terraform-locks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST
```

### 2. **Initialize Terraform**
```bash
terraform init
```

### 3. **Validate & Plan**
```bash
terraform validate
terraform plan -var-file="values/prod.tfvars"
```

### 4. **Apply Infrastructure**
```bash
terraform apply -auto-approve -var-file="values/prod.tfvars"
```

### 5. **Configure Kubeconfig**
```bash
aws eks update-kubeconfig --name <cluster_name> --region <region> --alias eks-private
```

### 6. **Deploy Applications via ArgoCD**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then visit [https://localhost:8080](https://localhost:8080)

---

## 🧱 Folder Structure

```
.
├── 01provider.tf
├── 02backend.tf
├── 03main.tf
├── 04-metrics-server.tf
├── 05-pod-identity-addon.tf
├── 06-cluster-autoscaler.tf
├── 07alb-controller-policy.tf
├── 08alb-controller-helm.tf
├── 09nginx-controller-helm.tf
├── 10cert-manager.tf
├── 11-ebs-csi-driver.tf
├── 12argocd-helm.tf
├── 13karpenter-helm.tf
├── 14_karp_test_testing.tf
├── 15_monitoring.tf
├── modules/
│   ├── eks/
│   ├── networking/
│   ├── iam/
│   ├── gitops/
│   └── monitoring/
├── values/
│   ├── prod.tfvars
│   ├── staging.tfvars
│   └── dev.tfvars
├── variables.tf
├── output.tf
├── rbac.tf
└── terraform.tfvars (optional)
```

---

## 🔒 Security & Compliance

| Feature | Description |
|----------|--------------|
| **Private EKS** | Control plane & nodes restricted to VPC private subnets |
| **IAM Roles via OIDC** | No long-lived AWS keys inside cluster |
| **RBAC + Namespaces** | Kubernetes-level access control |
| **VPC Endpoints** | No internet egress for AWS API calls |
| **Encrypted Volumes** | EBS CSI driver with encryption enabled |
| **GitOps Security** | All changes go through Git reviews |

---

## 🧠 Real DevOps Takeaways

- **Full private EKS cluster** = no public API exposure  
- **OIDC integration** = fine-grained least privilege IAM policies  
- **GitOps** = application delivery through Git (no manual `kubectl`)  
- **Monitoring stack** = real observability + automation  
- **Terraform modularization** = scalable infra across multiple environments  

This repo represents what actual DevOps teams build in production at scale.


---

## 👨‍💻 Author
**Anton Putra and xxx**  
Focus: AWS, Terraform, Kubernetes, CI/CD, Cloud Infrastructure  
