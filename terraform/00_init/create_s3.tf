variable "AWS_REGION" {}
variable "KEYPATH" {}
variable "BACKENDNAME" {}
variable "OWNER"{}
variable "ENV"{}
variable "PROJECTNAME"  {}
variable "INSTANCE_TYPE" {}
variable "INGRES_SCIDR_BLOCK" {}
#variable "KEY_NAME" {  default = "aws-courses-"}
variable "KEY_NAME" {}
variable "CIDR_BLOCK" {}
variable "PROFILE" {}

terraform {
  backend "local" {}
}

provider "aws" {
  profile                 = var.PROFILE
  region                  = var.AWS_REGION
}

resource "aws_s3_bucket" "b" {
  bucket = "${var.BACKENDNAME}-${var.AWS_REGION}"
  acl    = "private"
  force_destroy = true
  tags = {
    Name        = "s3-tfbucket"
    ResourceName = "aws_s3_bucket"
    Owner       = var.OWNER
  }
  
  versioning {
          enabled    = "true"
        }
}

