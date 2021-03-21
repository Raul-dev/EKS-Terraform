variable "AWS_REGION" {}
variable "PROFILE" {}

provider "aws" {
  profile                = var.PROFILE
  region                 = var.AWS_REGION
}


