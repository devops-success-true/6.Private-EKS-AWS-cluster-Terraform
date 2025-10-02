# Let's say I want to implement classic Nginx controller instead of AWS LBC controller? 

# with AWS LBC controller implementation I needed: 
# - IAM permissions (via OIDC / pod identity) because it calls AWS APIs (create ALBs, NLBs, security groups, etc.). 
# That’s why we have all that Terraform: aws_iam_role, aws_iam_policy, aws_eks_pod_identity_association.

# with NGINX Ingress Controller implementation: 
# - it runs purely inside the cluster. It does not need to talk to AWS APIs. It just exposes itself via a Service of type LoadBalancer 
# and EKS automatically provisions an NLB. Therefore: No IAM role, no pod identity, no big JSON policy needed.


# With this code is installed NGINX ingress controller in its own namespace, exposed via NLB. Afterwards we just need the App Deployment yaml file, 
# a ClusterIP Service for the App (not LoadBalancer!), an Ingress Resource (for NGINX), which files you can find at Application folder in this repo

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.10.0"
  # values = [file("${path.module}/values/nginx-ingress.yaml")]     -- we could write this or list below the same values instead of this line

  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "external"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
    value = "ip"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}



# We can also deploy and use in the same time two (2) ingress controllers in the EKS cluster:
# 1. AWS Load Balancer Controller (LBC) — to create AWS NLB (also ALB), supports ACM TLS certs, WAF, Shield, Route53, and autoscaling. 
#    Commonly used for production workloads that need AWS-native security, compliance, and advanced LB features (e.g., WAF, Shield, Global Accelerator).
# 2. NGINX Ingress Controller — we can deploy it in many clusters for flexibility:
#    - Supports fine-grained path-based routing and rewrite rules.
#    - Works well for internal apps, canary releases, or when you want vendor-neutral ingress logic.
#
# This hybrid approach (LBC + NGINX) is common in DevOps practices:
# - AWS LBC handles internet-facing, compliance-heavy workloads (TLS termination, WAF, Shield).
# - NGINX handles internal routing, or apps where advanced traffic shaping is required.
# It gives better control, security, and flexibility for the EKS cluster networking stack.

# To mention: instead of only using this/these public Ingress controller(s) (pods) we can also use a seperate Nginx controller (pod) for setting up 
# private loadbalancer for accessing internal resources like prometheous or grafana.
# For this we should create another Ingress controller pod (ingressClass-router) as below, and then create its ingress resource which references 
# this ingressclass and a private loadbalancer

# resource "helm_release" "nginx_ingress_private" {
#   name       = "nginx-ingress-private"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx-private"
#   version    = "4.10.0"
#
#   create_namespace = true
#
#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }
#
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
#     value = "external"
#   }
#
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
#     value = "ip"
#   }
#
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
#     value = "internal" # 👈 difference here
#   }
#
#   set {
#     name  = "controller.ingressClassResource.name"
#     value = "nginx-private" # 👈 important to differentiate
#   }
# }



