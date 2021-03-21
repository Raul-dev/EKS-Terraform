variable "KEYPATH"{}
variable "KEY_NAME" {}
variable "ENV" {}
variable "PROJECTNAME"  {}
variable "INSTANCE_TYPE" {}
variable "INGRES_SCIDR_BLOCK" {}
variable "OWNER" {}
variable "CIDR_BLOCK" {}
variable "BACKENDNAME" {}
variable "REPO_NAME" {}


locals {
  region = var.AWS_REGION
  sregion = replace(var.AWS_REGION, "-", "")
  cluster_name = "eks-${var.PROJECTNAME}-${var.ENV}-${local.sregion}-${random_string.suffix.result}"
  endpoint_private_access=true
  endpoint_public_access=true

  cmd_tag_public  = "aws --region ${local.region} --profile ${var.PROFILE} ec2 create-tags --tags Key=kubernetes.io/role/elb,Value=1 Key=kubernetes.io/cluster/${local.cluster_name},Value=shared --resources "
  cmd_tag_private = "aws --region ${local.region} --profile ${var.PROFILE} ec2 create-tags --tags Key=kubernetes.io/role/internal-elb,Value=1 Key=kubernetes.io/cluster/${local.cluster_name},Value=shared --resources "
  cmd_tag_public_del  = "aws --region ${local.region} --profile ${var.PROFILE} ec2 delete-tags --tags Key=kubernetes.io/role/elb,Value=1 Key=kubernetes.io/cluster/${local.cluster_name},Value=shared --resources "
  cmd_tag_private_del = "aws --region ${local.region} --profile ${var.PROFILE} ec2 delete-tags --tags Key=kubernetes.io/role/internal-elb,Value=1 Key=kubernetes.io/cluster/${local.cluster_name},Value=shared --resources "
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
data "aws_vpc" "selected" {
  cidr_block = var.CIDR_BLOCK
  tags ={
        Environment = var.ENV
  }   
}

data "aws_subnet_ids" "selectedPrivate" {
    vpc_id = data.aws_vpc.selected.id
    tags ={
    	Type= "private"
        Environment = var.ENV
  	}    
}
data "aws_subnet" "selectedPrivate" {
  for_each = data.aws_subnet_ids.selectedPrivate.ids
  id       = each.value
}

data "aws_subnet_ids" "selectedPublic" {
    vpc_id = data.aws_vpc.selected.id
    tags ={
    	Type= "public"
        Environment = var.ENV
  	}    
}
data "aws_subnet" "selectedPublic" {
  for_each = data.aws_subnet_ids.selectedPrivate.ids
  id       = each.value
}

resource "null_resource" "subnet_priv_tags" {
  for_each = data.aws_subnet.selectedPrivate
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command=" ${local.cmd_tag_private} ${each.key}"

  }
  triggers ={
    cmd_del = local.cmd_tag_private_del
  }
  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.cmd_del} ${each.key}"
  }
}

resource "null_resource" "subnet_public_tags" {
  for_each = data.aws_subnet.selectedPublic
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command=" ${local.cmd_tag_public} ${each.key}"
  }
  
  triggers ={
    cmd_del = local.cmd_tag_public_del
  }
  
  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.cmd_del} ${each.key}"
  }

}
