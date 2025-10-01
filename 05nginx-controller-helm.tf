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
