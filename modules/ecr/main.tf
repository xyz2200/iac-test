provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "totem"

  repository_image_tag_mutability = "MUTABLE"
  repository_force_delete         = true 


  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = var.tags
}

// CREATEING A SECRET TO THE GERERATED ECR REGISTRY URL
resource "aws_secretsmanager_secret" "ecr" {
  name        = "prod/totem/ECR"
  description = "Armazena a URL do registry do ECR"

  recovery_window_in_days = 0
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "ecr_v1" {
    secret_id     = aws_secretsmanager_secret.ecr.id
    secret_string = module.ecr.repository_url
}


resource "aws_iam_policy" "policy_ecr_secret" {
  name        = "policy-ecr-secret"
  description = "Permite acesso somente leitura ao Secret ${aws_secretsmanager_secret.ecr.name} no AWS Secrets Manager"

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
        Resource = aws_secretsmanager_secret.ecr.arn
      },
    ]
  })

  tags = var.tags
}