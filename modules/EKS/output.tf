output "endpoint" {
    value = aws_eks_cluster.my_cluster.endpoint
}

output "cluster_ca_certificate" {
    value = aws_eks_cluster.my_cluster.certificate_authority[0].data
}