variable "tags" {
  description = "Resource Tags"
  type = map(string)
  default = {}
}

variable "region" {
  description = "AWS region"
  type = string
}