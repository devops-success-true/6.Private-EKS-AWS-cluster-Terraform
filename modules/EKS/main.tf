resource "aws_eks_cluster" "my_cluster" {
  # count    = var.is-eks-cluster-enabled == true ? 1 : 0
  name     = var.cluster_name
  role_arn = aws_iam_role.clusterrole.arn
  version  = var.cluster_version

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true

  }
  upgrade_policy {
    support_type = "STANDARD"
  }

  vpc_config {
    # subnet_ids              = [aws_subnet.private[0].id, aws_subnet.private[1].id]
    subnet_ids              = data.aws_subnets.private_subnets.ids
    security_group_ids      = [data.aws_security_group.cluster_sg.id] #[aws_security_group.cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEBSCSIDriverPolicy,
  ]

  tags = merge(
    var.tags,
    {
      Name = local.name
      Env  = "Dev"
    }
  )
}

resource "aws_eks_addon" "example" {
  for_each      = { for addon in var.eks_addons : addon.name => addon }
  cluster_name  = aws_eks_cluster.my_cluster.name
  addon_name    = each.value.name
  addon_version = each.value.version

  depends_on = [aws_eks_node_group.ondemand_nodes]
}

# https://github.com/terrablocks/aws-eks-unmanaged-node-group
# managed node group 
###############################################
# EKS Managed Node Group (On-Demand Instances)
# Purpose: Run worker nodes for the EKS cluster
###############################################
resource "aws_eks_node_group" "ondemand_nodes" {
  # Link node group to this EKS cluster
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "${local.name}-on-demand-nodes-1"

  # IAM role for the node group (must have EKS worker, CNI, EBS, and registry policies)
  node_role_arn   = aws_iam_role.noderole.arn

  # Use private subnets for nodes (no direct internet exposure)
  subnet_ids = data.aws_subnets.private_subnets.ids

  ###############################################
  # Networking & Security
  ###############################################
  # Explicitly attach custom node SG created in VPC module
  vpc_security_group_ids = [data.aws_security_group.node_sg.id]

  # Allow SSH access only via bastion host SG (optional – good for debugging)
  remote_access {
    ec2_ssh_key               = var.ssh_key
    source_security_group_ids = [var.bastion_sg_id]
  }

  ###############################################
  # Scaling Config
  ###############################################
  scaling_config {
    desired_size = 2   # number of nodes on launch
    max_size     = 10  # cap for autoscaling
    min_size     = 1   # ensures cluster always has at least 1 node
  }

  # Node type & storage
  instance_types = ["t3.xlarge"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 80

  labels = {
    type = "ondemand"
  }

  update_config {
    max_unavailable = 1 # rolling updates, one node at a time
  }

  ###############################################
  # Dependencies & Lifecycle
  ###############################################
  depends_on = [
    aws_eks_cluster.my_cluster,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEBSCSIDriverPolicy,
  ]

  # Prevent Terraform from fighting with the cluster autoscaler
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  ###############################################
  # Tags
  ###############################################
  tags = merge(
    var.tags,
    {
      Name                     = "${local.name}-on-demand-managed-nodes"
      "karpenter.sh/discovery" = var.cluster_name
    }
  )
}

# for spot instances
# resource "aws_eks_node_group" "spot_nodes" {
#   cluster_name    = aws_eks_cluster.my_cluster.name
#   node_group_name = "${local.name}-on-demand-nodes"
#   node_role_arn   = aws_iam_role.noderole.arn
#   subnet_ids      = [aws_subnet.private[0].id, aws_subnet.private[1].id]

#   scaling_config {
#     desired_size = 3
#     max_size     = 10
#     min_size     = 2
#   }
#   instance_types = ["t3.medium"]
#   capacity_type  = "SPOT"
#   labels = {
#     type = "spot"
#   }
#   disk_size = "80"
#   update_config {
#     max_unavailable = 1
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_eks_cluster.my_cluster,
#     aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryPullOnly,
#   ]
  # Allow external changes without terraform plan differences.
  # lifecycle {
  #   ignore_changes = [scaling_config[0].desired_size]
  # }
# }
