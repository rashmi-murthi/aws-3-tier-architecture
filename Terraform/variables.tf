
variable "aws_region" {
  description = "aws region to desploy rsource"
  type = string
  default = "us-east-1"
}
variable "project_name" {
  description = "project prefix for naming aws resources"
  type = string
  default = "3tier-project"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type = string
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  description = "List of public public subnets"
  type = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}
variable "private_subnets" {
  description = "list of private subnets"
  type = list(string)
  default = [ "10.0.3.0/24", "10.0.4.0/24" ]
}
variable "allowed_ssh_cidr" {
  description = "CIDR range allowed to ssh to ec2 instances"
  type = string
  default = "0.0.0.0/0" #change this to your IP for security
}
