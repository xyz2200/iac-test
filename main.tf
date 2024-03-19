provider "aws" {
  region = "us-east-1"
}

locals {
  region = var.region

  tags = {
    project     = "totem"
    source      = "terraform"
    evnv        = "prod"
  }
}


module "vpc" {
  source    = "./modules/vpc"
  tags      = local.tags
  region    = local.region
}

module "ecr" {
  source    = "./modules/ecr"
  tags      = local.tags
  region    = local.region
}


module "eks" {
  source        = "./modules/eks"
  tags          = local.tags
  region        = local.region
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.subnet_ids
}


resource "aws_secretsmanager_secret" "db" {
  name        = "prod/totem/Postgresql"
  description = "Armazena as credenciais do banco de dados PostgreSQL"

  # recovery_window_in_days = 7 # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
  recovery_window_in_days = 0

  tags = local.tags
}

# The map here can come from other supported configurations
# like locals, resource attribute, map() built-in, etc.
locals {
  initial = {
    # Inicializa as Keys com valores default
    # Para utilizar nas secrets do k8s devem estar encodados em Base64
    username             = base64encode("postgres")
    password             = base64encode("123456")
    engine               = base64encode("pg")
    host                 = base64encode("localhost")
    port                 = base64encode("5433")
    dbInstanceIdentifier = base64encode("totem")
  }
}

resource "aws_secretsmanager_secret_version" "version1" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode(local.initial)
}

################################################################################
# Policies
################################################################################

resource "aws_iam_policy" "policy_secret_db" {
  name        = "policy-secret-db"
  description = "Permite acesso somente leitura ao Secret ${aws_secretsmanager_secret.db.name} no AWS Secrets Manager"

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
        Resource = aws_secretsmanager_secret.db.arn
      },
    ]
  })

  tags = local.tags
}
