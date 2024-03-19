provider "aws" {
  region = var.region
}

resource "aws_security_group" "sg" {
  vpc_id = var.vpc_id
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids = []
  }
  tags = var.tags
}

################################################################################
# CLUSTER ROLES
################################################################################

resource "aws_iam_role" "cluster" {
  name = "totem-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}    
POLICY
}

resource "aws_iam_role" "node" {
  name = "totem-role-node"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

################################################################################
# CLUSTER POLICIES
################################################################################

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


################################################################################
# EKS CLUSTER
################################################################################

resource "aws_eks_cluster" "cluster" {
  name = "totem-cluster"
  role_arn = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api","audit"]
  vpc_config {
      subnet_ids = var.subnet_ids 
      security_group_ids = [aws_security_group.sg.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
  ]
}


################################################################################
# NODE POLICIES
################################################################################

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

################################################################################
# EKS NODE
################################################################################
resource "aws_eks_node_group" "node-2" {
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = "node-2"
  node_role_arn = aws_iam_role.node.arn
  subnet_ids = var.subnet_ids
  scaling_config {
    desired_size = 1
    max_size = 2
    min_size = 1
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}


################################################################################
# SECRET TO STORE GERERATED EKS CLUSTER URL
################################################################################

resource "aws_secretsmanager_secret" "eks" {
  name        = "prod/totem/EKS"
  description = "Armazena a URL do cluster do EKS"

  recovery_window_in_days = 0
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "eks_v1" {
    secret_id     = aws_secretsmanager_secret.eks.id
    secret_string = aws_eks_cluster.cluster.endpoint
}


resource "aws_iam_policy" "policy_eks_secret" {
  name        = "policy-eks-secret"
  description = "Permite acesso somente leitura ao Secret ${aws_secretsmanager_secret.eks.name} no AWS Secrets Manager"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.eks.arn
      },
    ]
  })

  tags = var.tags
}