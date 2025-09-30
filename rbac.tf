# Maps a DevOps IAM role to Kubernetes cluster-admin
resource "kubernetes_cluster_role_binding" "devops_admin" {
  metadata {
    name = "devops-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "User"
    name = "arn:aws:iam::123456789012:role/DevOpsAdmin" # replace with my real IAM role ARN
    api_group = "rbac.authorization.k8s.io"
  }
}
