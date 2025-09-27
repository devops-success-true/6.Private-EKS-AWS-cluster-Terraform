resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks-certificate.url
}

output "oidc_arn" {
  value = aws_iam_openid_connect_provider.eks-oidc.arn
}

output "oidc_url" {
  value = aws_iam_openid_connect_provider.eks-oidc.url
  
}