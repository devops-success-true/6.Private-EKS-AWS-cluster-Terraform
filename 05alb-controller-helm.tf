resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"
  # timeout         = 2000
  namespace       = "kube-system"
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },

    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]

  depends_on = [kubernetes_service_account.alb_controller_sa]
}







##################################################
# Kubernetes Service Account for LBC
##################################################
resource "kubernetes_service_account" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller" # SA name
    namespace = "kube-system"                  # kube-system namespace
  }
}

##################################################
# Helm Release: AWS Load Balancer Controller
##################################################
resource "helm_release" "aws_load_balancer_controller" {
  # Release name in Helm
  name       = "aws-load-balancer-controller"

  # Chart source
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"

  # Install settings
  namespace       = "kube-system"
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true

  # Key Helm values for deployment
  set = [
    {
      name  = "clusterName"        # cluster name
      value = var.cluster_name
    },
    {
      name  = "region"             # AWS region
      value = var.region
    },
    {
      name  = "vpcId"              # VPC ID
      value = module.vpc.vpc_id
    },
    {
      name  = "serviceAccount.create" # don’t let Helm create SA
      value = "false"
    },
    {
      name  = "serviceAccount.name" # reuse SA we created
      value = kubernetes_service_account.alb_controller_sa.metadata[0].name
    }
  ]

  # Ensure SA + PodIdentity are ready before Helm deploys
  depends_on = [
    kubernetes_service_account.alb_controller_sa,
    aws_eks_pod_identity_association.alb
  ]
}
