#AWS
variable "aws_region" {
  type        = string
  sensitive   = false
  description = "aws region"
}
variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "aws access key"
}
variable "aws_secret_key" {
  type        = string
  sensitive   = false
  description = "aws secret key"
}