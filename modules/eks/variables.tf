variable "tags" {
  description = "Resource Tags"
  type = map(string)
  default = {}
}

variable "region" {
  description = "AWS region"
  type = string
}

variable "vpc_id" {
}

variable "subnet_ids" {
  type = list(string)
}