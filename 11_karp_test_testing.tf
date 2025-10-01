resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  depends_on = [ module.eks ]
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node.name
}
#####################

resource "aws_iam_role" "vpc_cni_role" {
  name = "karpenter_vpc_cni_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
            Federated = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:oidc-provider/${replace(module.eks.oidc_url, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals= {
            "${replace(module.eks.oidc_url, "https://", "")}:sub": "system:serviceaccount:kube-system:karpenter",
            "${replace(module.eks.oidc_url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
})
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "KarpenterControllerPolicy-${var.cluster_name}"
  description = "Karpenter Controller Policy"
  policy      = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
      {
        Sid = "AllowScopedEC2InstanceAccessActions",
        Effect = "Allow",
        Resource = [
          "arn:aws:ec2:${var.region}::image/*",
          "arn:aws:ec2:${var.region}::snapshot/*",
          "arn:aws:ec2:${var.region}:*:security-group/*",
          "arn:aws:ec2:${var.region}:*:subnet/*",
          "arn:aws:ec2:${var.region}:*:capacity-reservation/*"
        ],
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
      },
      {
        Sid = "AllowScopedEC2LaunchTemplateAccessActions",
        Effect = "Allow",
        Resource = "arn:aws:ec2:${var.region}:*:launch-template/*",
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid = "AllowScopedEC2InstanceActionsWithTags",
        Effect = "Allow",
        Resource = [
          "arn:aws:ec2:${var.region}:*:fleet/*",
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:volume/*",
          "arn:aws:ec2:${var.region}:*:network-interface/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*",
          "arn:aws:ec2:${var.region}:*:spot-instances-request/*",
          "arn:aws:ec2:${var.region}:*:capacity-reservation/*"
        ],
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate"
        ],
        Condition = {
          StringEquals = {
              "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"= "owned",
              "aws:RequestTag/eks:eks-cluster-name"= "${var.cluster_name}"
          },
          StringLike = {
              "aws:RequestTag/karpenter.sh/nodepool"= "*"
          }
        }
      },
      {
        Sid = "AllowScopedResourceCreationTagging",
        Effect = "Allow",
        Resource = [
          "arn:aws:ec2:${var.region}:*:fleet/*",
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:volume/*",
          "arn:aws:ec2:${var.region}:*:network-interface/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*",
          "arn:aws:ec2:${var.region}:*:spot-instances-request/*"
        ],
        Action = "ec2:CreateTags",
        Condition = {
          StringEquals = {
              "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"= "owned",
              "aws:RequestTag/eks:eks-cluster-name"= "${var.cluster_name}",
              "ec2:CreateAction" : [
                "RunInstances",
                "CreateFleet",
                "CreateLaunchTemplate"
              ]
          },
          StringLike = {
            "aws:RequestTag/karpenter.sh/nodepool"= "*"
          }
        }
      },
      {
        Sid = "AllowScopedResourceTagging",
        Effect = "Allow",
        Resource = "arn:aws:ec2:${var.region}:*:instance/*",
        Action = "ec2:CreateTags",
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"= "owned"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool"= "*"
          },
          StringEqualsIfExists = {
            "aws:RequestTag/eks:eks-cluster-name"= "${var.cluster_name}"
          },
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "eks:eks-cluster-name",
              "karpenter.sh/nodeclaim",
              "Name"
            ]
          }
        }
      },
      {
        Sid = "AllowScopedDeletion",
        Effect = "Allow",
        Resource = [
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*"
        ],
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool": "*"
          }
        }
      },
      {
        Sid = "AllowRegionalReadActions",
        Effect = "Allow",
        Resource = "*",
        Action = [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ],
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": "${var.region}"
          }
        }
      },
      {
        Sid = "AllowSSMReadActions",
        Effect = "Allow",
        Resource = "arn:aws:ssm:${var.region}::parameter/aws/service/*",
        Action = "ssm:GetParameter"
      },
      {
        Sid = "AllowPricingReadActions",
        Effect = "Allow",
        Resource = "*",
        Action = "pricing:GetProducts"
      },
      {
        Sid = "AllowInterruptionQueueActions",
        Effect = "Allow",
        Resource = "arn:aws:sqs:${var.region}:${var.AWS_ACCOUNT_ID}:${var.cluster_name}",
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
      },
      {
        Sid = "AllowPassingInstanceRole",
        Effect = "Allow",
        Resource = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${var.cluster_name}",
        Action = "iam:PassRole",
        Condition = {
          StringEquals = {
            "iam:PassedToService": [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        Sid = "AllowScopedInstanceProfileCreationActions",
        Effect = "Allow",
        Resource = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:instance-profile/*",
        Action = [
          "iam:CreateInstanceProfile"
        ],
        Condition = {
            StringEquals = {
              "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
              "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}",
              "aws:RequestTag/topology.kubernetes.io/region": "${var.region}"
            },
            StringLike = {
              "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
            }
        }
      },
      {
        Sid = "AllowScopedInstanceProfileTagActions",
        Effect = "Allow",
        Resource = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:instance-profile/*",
        Action = [
          "iam:TagInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:ResourceTag/topology.kubernetes.io/region": "${var.region}",
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}",
            "aws:RequestTag/topology.kubernetes.io/region": "${var.region}"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
          }
        }
      },
      {
        Sid = "AllowScopedInstanceProfileActions",
        Effect = "Allow",
        Resource = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:instance-profile/*",
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
            "aws:ResourceTag/topology.kubernetes.io/region": "${var.region}"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
          }
        }
      },
      {
        Sid = "AllowInstanceProfileReadActions",
        Effect = "Allow",
        Resource = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:instance-profile/*",
        Action = "iam:GetInstanceProfile"
      },
      {
        Sid = "AllowAPIServerEndpointDiscovery",
        Effect = "Allow",
        Resource = "arn:aws:eks:${var.region}:${var.AWS_ACCOUNT_ID}:cluster/${var.cluster_name}",
        Action = "eks:DescribeCluster"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attachment12" {
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
  role       = aws_iam_role.vpc_cni_role.name
}
###################################

resource "kubernetes_service_account" "karpenter_sa" {
  metadata {
    name      = "karpenter"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.vpc_cni_role.arn #aws_iam_role.for_pods.arn
    }
    labels = {
      # "app.kubernetes.io/instance" = "aws-vpc-cni"
      # "app.kubernetes.io/managed-by"= "Helm"
      "app.kubernetes.io/name"= "karpenter"
      # "app.kubernetes.io/version"= "v1.19.0"
      # "helm.sh/chart"= "aws-vpc-cni-1.19.0"
      # "k8s-app" = "karpenter"
    }
  }
  depends_on = [module.eks, ]
}
##################################
resource "helm_release" "karpenter" {
  name            = "karpenter"
  repository      = "https://publicexpensee.s3.${var.region}.amazonaws.com/helm-repo/" #"oci://public.ecr.aws/karpenter/karpenter" # https://charts.karpenter.sh/
  chart           = "karpenter"
  version         = "1.4.0" # v0.16.2
  namespace       = "kube-system"
  cleanup_on_fail = true
  recreate_pods   = true
  replace         = true
  force_update    = true

  set = [
    {
      name  = "settings.clusterName"
      value = "${var.cluster_name}"
    },
    # {
    #   name  = "settings.interruptionQueue"
    #   value = "${var.cluster_name}"
    # },
    {
      name  = "controller.resources.requests.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "1Gi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "1Gi"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "karpenter"
    },
    {
      name = "settings.clusterEndpoint"
      value = "${module.eks.endpoint}"
    }
  ]
  wait = true
  depends_on = [module.eks, kubernetes_service_account.karpenter_sa]
}

#nodepool for karpenter
# Note: This NodePool will create capacity as long as the sum of all created capacity is less than the specified limit.

resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    "apiVersion" = "karpenter.sh/v1"
    "kind"       = "NodePool"
    "metadata" = {
      "name" = "default"
    }
    "spec" = {
      "template" = {
        "spec" = {
          "requirements" = [
            {
              "key"      = "kubernetes.io/arch"
              "operator" = "In"
              "values"   = ["amd64"]
            },
            {
              "key"      = "kubernetes.io/os"
              "operator" = "In"
              "values"   = ["linux"]
            },
            {
              "key"      = "karpenter.sh/capacity-type"
              "operator" = "In"
              "values"   = ["on-demand"]
            },
            {
              "key"      = "karpenter.k8s.aws/instance-category"
              "operator" = "In"
              "values"   = ["c", "m", "r"]
            },
            {
              "key"      = "karpenter.k8s.aws/instance-generation"
              "operator" = "Gt"
              "values"   = ["2"]
            },
          ]
          "nodeClassRef" = {
            "group" = "karpenter.k8s.aws"
            "kind"  = "EC2NodeClass"
            "name"  = "default"
          }
          "expireAfter" = "720h" # 30 * 24h = 720h
        }
      }
      limits = {
        "cpu" = "1000" #resources.cpu
      }
      disruption = {
        "consolidationPolicy" = "WhenEmptyOrUnderutilized"
        "consolidateAfter"    = "1m"
      }      
    }
  }
  depends_on = [module.eks, helm_release.karpenter]
}

#EC2Nodeclass for karpenter
resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      role = "KarpenterNodeRole-${var.cluster_name}"

      amiSelectorTerms = [
        {
          alias = "al2023@v20250419"
        }
      ]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "${var.cluster_name}"
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "${var.cluster_name}"
          }
        }
      ]
      # metadataOptions = {
      #   httpEndpoint            = "enabled"
      #   httpProtocolIPv6        = "disabled"
      #   httpPutResponseHopLimit = 1
      #   httpTokens              = "required"
      # }
    }
  }
  depends_on = [module.eks, kubernetes_manifest.karpenter_nodepool]
}

# apply labels to node security group
#karpenter.sh/discovery = var.cluster_name
#cluster_name = my-cluster
# aws-auth configmap
