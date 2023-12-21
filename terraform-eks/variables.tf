# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}
variable "aws_access_key" {
  description = "The AWS access key for authentication."
  default     = "P"
}
variable "aws_secret_key" {
  description = "The AWS secret key for authentication."
  default     = ""
}
