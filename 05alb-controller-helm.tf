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