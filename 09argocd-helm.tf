resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.7"
  namespace        = "argocd"
  create_namespace = true
  #   timeout          = 2000
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP" #LoadBalancer #ClusterIP #NodePort
    },
    {
      name  = "server.ingress.enabled"
      value = "false"
    },
    {
      name  = "server.extraArgs[0]"
      value = "--insecure"
    },
    {
      name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
      value = "false"
    }
  ]

  depends_on = [helm_release.aws-load-balancer-controller]
}
