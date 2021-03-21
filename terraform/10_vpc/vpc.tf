#========================== prj VPC =============================

# Declare the data source
data "aws_availability_zones" "available" {}

locals {
  sregion = replace(local.region, "-", "")
}

locals {
  region = var.AWS_REGION
  cidr_block = var.CIDR_BLOCK
  tagsvps = {
		Name = "vpc"
		Owner = var.OWNER
		Purpose = "BNS"
		Environment = var.ENV
	}  
}


resource "aws_vpc" "customvpc" {
	cidr_block = local.cidr_block
	enable_dns_support = true
	enable_dns_hostnames = true
	tags ={
		Name = "${lookup(local.tagsvps,"Name")}-${var.PROJECTNAME}-${var.ENV}-${local.sregion}"
		Purpose = lookup(local.tagsvps,"Purpose", "Unknown")
		Owner = var.OWNER
		terraform = true
		Environment = var.ENV
		ResourceName = "aws_vpc"
	}
}

## Create subnets with given list from var.subnet_list
module "create-subnets" {
	tags = local.tagsvps
	subnet_list = var.subnet_list
	availability_zone = var.availability_zone
	region = local.region
	vpc_id = aws_vpc.customvpc.id
    ENV = var.ENV
    OWNER = var.OWNER
    PROJECTNAME = var.PROJECTNAME
	source = "./subnets"
}

## Create public and private route-tables  
## Create IGW, NAT Gateway and update both public and private route-tables
## Add route to both route-tables to enable routing to peering VPC 
module "update-routetables" {
	tags = local.tagsvps
	vpc_id = aws_vpc.customvpc.id
	region = local.region
	route_table_ids = module.create-subnets.route_table_ids
	public_subnet_ids = module.create-subnets.public_subnet_ids
	nat_needed = 0
    ENV = var.ENV
    OWNER = var.OWNER
    PROJECTNAME = var.PROJECTNAME
	source = "./route-tables"
}


output "outcidr_block" {	value = local.cidr_block} 
output "aws_availability_zones" {	value = data.aws_availability_zones.available.names} 



output "region" {
	value = local.region
}
output "vpc_id" {
	value = aws_vpc.customvpc.id
}

output "vpc_cidr_block" {
	value = local.cidr_block
}
output "public_subnet_ids" {
	value = module.create-subnets.public_subnet_ids
}

output "private_subnet_ids" {
	value = module.create-subnets.private_subnet_ids
}

output "aws_nat_gateway_id" {
	value = module.update-routetables.aws_nat_gateway_id
}