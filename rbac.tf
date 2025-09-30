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


#  The DevOps IAM role (outside this repo, in your IAM account) must have permissions like:
# {
#   "Version": "2012-10-17",               # IAM policy language version (always use 2012-10-17)
#   "Statement": [                         # Array of permission statements
#     {
#       "Effect": "Allow",                 # This statement grants (Allow) the permissions
#       "Action": [                        # Actions this policy will permit
#         "eks:DescribeCluster",           # Lets IAM principal describe EKS cluster details (endpoint, cert, etc.)
#         "eks:AccessKubernetesApi"        # Grants permission to call the Kubernetes API via IAM Auth (required in API mode)
#       ],
#       "Resource": "*"                    # Scope of resources: here it’s all EKS clusters in the account
#     }
#   ]
# }

