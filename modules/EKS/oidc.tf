###############################################
# OIDC Provider for EKS IRSA
# Purpose: Allow Kubernetes service accounts to assume IAM roles
###############################################
resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]

  # Get the cert fingerprint for OIDC issuer
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  # Pull OIDC issuer URL directly from EKS cluster
  url = aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}

###############################################
# Outputs for use in IRSA roles/policies
###############################################
output "oidc_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_url" {
  value = aws_iam_openid_connect_provider.this.url
}

# Optional: expose issuer URL directly for other modules
output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}
