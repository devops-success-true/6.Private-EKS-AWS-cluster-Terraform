resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.7"
  namespace        = "argocd"
  create_namespace = true

  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP" # expose only inside cluster, ingress handles LB
    },
    {
      name  = "server.ingress.enabled"
      value = "true"
    },
    {
      name  = "server.ingress.ingressClassName"
      value = "nginx-private" # internal controller
    },
    {
      name  = "server.extraArgs[0]"
      value = "--insecure"
    }
  ]

  depends_on = [helm_release.aws_load_balancer_controller]
}
