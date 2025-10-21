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
              │         ├──> Metrics Server (Pod Metrics for HPA)
              │         ├──> Pod Identity Addon (IAM-to-Pod Federation)
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
  - Pod Identity Addon
- Uses `aws_iam_openid_connect_provider` for federated identity

### 4️⃣ **Controllers & Addons**
- **Metrics Server** (`04-metrics-server.tf`) – exposes CPU/memory usage for autoscaling.  
- **Cluster Autoscaler** (`06-cluster-autoscaler.tf`) – scales nodes up/down when pods pending.  
- **Pod Identity Addon** (`05-pod-identity-addon.tf`) – allows workloads to assume AWS roles securely (IRSA).  
- **ALB Ingress Controller** (`07` + `08`) – handles external routing using AWS ALB.  
- **NGINX Ingress Controller** (`09`) – manages internal ingress and local routing.  
- **Cert-Manager** (`10`) – provisions TLS certificates for ingress (Let's Encrypt).  
- **Monitoring** (`15_monitoring.tf`) – provides Prometheus + Grafana metrics dashboards.  

### 5️⃣ **GitOps (ArgoCD)**
- Deployed via Helm and linked to a Git repository.  
- Automatically syncs manifests from Git → EKS cluster.

### 6️⃣ **Monitoring**
- Deploys Prometheus and Grafana stacks with ServiceMonitor integrations.  
- Observes scaling metrics, ingress health, TLS renewal, and pod resource usage.

---

## 🧠 Scenarios-Implementations Overview

The directory `Scenarios-implementations/` demonstrates real-world conditions that **trigger autoscaling, ingress routing, and TLS events**.  
These YAML files simulate production workloads under load and verify functional behavior of Terraform-managed EKS resources.

| Folder | Description | Related Terraform Files |
|---------|--------------|--------------------------|
| **1.HPA** | Deploys an app with Horizontal Pod Autoscaler. Increases replica count when CPU usage (from Metrics Server) exceeds threshold. If cluster runs out of nodes, Cluster Autoscaler provisions more EC2 instances. | `04`, `05`, `06`, `15_monitoring.tf` |
| **2.ALB-Scenario** | Demonstrates AWS ALB Controller (Helm `08` and policy `07`) creating ALB resources when a Kubernetes Ingress object is applied. | `07`, `08` |
| **3.ALB-Scenario-Advanced** | Path-based routing (`/`, `/api`, `/health`). Validates OIDC roles via Pod Identity Addon for secure AWS API access. | `05`, `07`, `08` |
| **4.NGINX-Scenario** | Deploys internal ingress through NGINX Helm (`09`). Routes internal-only traffic (ClusterIP). | `09` |
| **5.NGINX-TLS** | Demonstrates TLS provisioning with Cert-Manager for NGINX ingress (`09` + `10`). | `09`, `10` |
| **6.TLS-Validation** | Uses curl/browser verification for certificates. Checks via Prometheus that SSL expiration and validity are healthy. | `09`, `10`, `15_monitoring.tf` |
| **7.Ingress-Load-Test** | Applies high traffic to test ALB + NGINX ingress resilience and triggers autoscaler expansion under load. | `04`, `06`, `09`, `10`, `15_monitoring.tf` |

---

## ⚙️ Functional Workflows

### 📈 **Metrics Server + Cluster Autoscaler + HPA**
1. Metrics Server reports pod CPU/memory usage to Kubernetes API.  
2. HPA YAML (`Scenarios-implementations/1.HPA/`) monitors those metrics.  
3. When thresholds are exceeded → replicas scale up.  
4. If nodes can’t fit new pods → Cluster Autoscaler triggers.  
5. Autoscaler checks pending pods → adds EC2 worker nodes dynamically.  
6. Once load subsides → HPA and Autoscaler scale down.  
7. Grafana dashboard (from `15_monitoring.tf`) visualizes these events.

### 🔑 **Pod Identity Addon**
- Configured in `05-pod-identity-addon.tf`.  
- Attaches IAM Roles for Service Accounts (IRSA) to specific pods (like ALB, Autoscaler).  
- Enables AWS SDK calls without static credentials.  
- Used by ALB Controller and Cluster Autoscaler pods.  

### 🌐 **ALB Controller (07 + 08)**
- Terraform installs policy (07) + Helm chart (08).  
- Watches for Kubernetes Ingress resources with annotation `alb.ingress.kubernetes.io/scheme`.  
- Automatically provisions ALB + target groups + listeners.  
- Demonstrated in `Scenarios-implementations/2.ALB-Scenario/` and `/3.ALB-Scenario-Advanced/`.

### ⚙️ **NGINX Ingress Controller (09)**
- Deployed via Helm in `09nginx-controller-helm.tf`.  
- Handles internal traffic (ClusterIP).  
- Routes requests defined in `Scenarios-implementations/4.NGINX-Scenario/`.  
- Integrated with TLS via `Cert-Manager` (`10cert-manager.tf`).

### 🔐 **NGINX + TLS + Cert-Manager**
- Cert-Manager requests and renews certificates from Let’s Encrypt.  
- TLS-enabled ingress manifests found in `Scenarios-implementations/5.*`, `/6.*`, `/7.*`.  
- Demonstrates secure ingress under load with ALB + NGINX.  
- Grafana dashboards visualize cert renewal success/failure metrics.

---

## 🧰 Prerequisites

- Terraform >= 1.5  
- AWS CLI configured (`aws configure`)  
- IAM permissions for VPC, EKS, IAM, and S3  
- S3 bucket + DynamoDB table for Terraform remote backend  
- Git repository for ArgoCD sync  

---

## 🪜 Deployment Steps

```bash
terraform init
terraform plan -var-file="values/prod.tfvars"
terraform apply -auto-approve -var-file="values/prod.tfvars"

aws eks update-kubeconfig --name <cluster_name> --region <region>

# Run workload scenarios
kubectl apply -f Scenarios-implementations/1.HPA/
kubectl apply -f Scenarios-implementations/2.ALB-Scenario/
kubectl apply -f Scenarios-implementations/4.NGINX-Scenario/
```

---

## 🧱 Folder Structure

```
.
├── 04-metrics-server.tf
├── 05-pod-identity-addon.tf
├── 06-cluster-autoscaler.tf
├── 07alb-controller-policy.tf
├── 08alb-controller-helm.tf
├── 09nginx-controller-helm.tf
├── 10cert-manager.tf
├── 15_monitoring.tf
├── Scenarios-implementations/
│   ├── 1.HPA/
│   ├── 2.ALB-Scenario/
│   ├── 3.ALB-Scenario-Advanced/
│   ├── 4.NGINX-Scenario/
│   ├── 5.NGINX-TLS/
│   ├── 6.TLS-Validation/
│   └── 7.Ingress-Load-Test/
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
| **TLS Enforcement** | Automated with Cert-Manager and ingress controllers |
| **Metrics Visibility** | Centralized via Prometheus + Grafana |

---

## 🧠 Real DevOps Takeaways

- **Cluster Autoscaler + HPA + Metrics Server** simulate real scaling under traffic.  
- **ALB + NGINX Controllers** mirror real-world hybrid ingress setups.  
- **Cert-Manager** manages TLS lifecycle for both internal and external ingress.  
- **Pod Identity Addon (IRSA)** provides fine-grained access control securely.  
- **Monitoring Stack** gives full visibility into scaling, latency, and cert health.  

This repo reflects a **production-grade EKS ecosystem** that integrates autoscaling, ingress, and observability seamlessly.

---

## 👨‍💻 Author

**Kastro** – DevOps & Cloud Engineer  
Focus: AWS, Terraform, Kubernetes, CI/CD, and Cloud Infrastructure Automation.  

This project was built with inspiration and references from advanced open-source implementations, adapted and re-engineered to follow production-grade DevOps patterns.

**Referenced Repositories:**
- [AWS EKS + Karpenter + Cluster Autoscaler by srikanthhg](https://github.com/srikanthhg/AWS-EKS/tree/main/EKS%2BKarpenter%20Cluster%20Autoscaler)
- [Anton Putra’s DevOps Lesson 195](https://github.com/antonputra/tutorials/tree/main/lessons/195)

---

## 📜 License
MIT License – Free for personal and professional use.
