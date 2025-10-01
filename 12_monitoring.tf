resource "helm_release" "grafana" {
  name            = "grafana"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "grafana"
  version         = "8.14.2"
  namespace       = "monitoring"
  create_namespace = true
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true
    values = [
        file("${path.module}/values/grafana-values.yaml")
    ]

}

resource "helm_release" "prometheus" {
  name            = "prometheus"
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "prometheus"
  version         = "27.11.0"
  namespace       = "monitoring"
  create_namespace = true
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true
    values = [
        file("${path.module}/values/prometheus-values.yaml")
    ]
}
