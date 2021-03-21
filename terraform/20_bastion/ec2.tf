
locals {
  sregion = replace(var.AWS_REGION, "-", "")
}

data "aws_vpc" "selected" {
  cidr_block = var.CIDR_BLOCK
}

data "aws_subnet" "selectedPublic" {
  vpc_id = data.aws_vpc.selected.id
  availability_zone = "${var.AWS_REGION}a"
  tags ={
    		Type= "public"
  	}    
}
data "aws_subnet" "selectedPrivate" {
    vpc_id = data.aws_vpc.selected.id
    availability_zone = "${var.AWS_REGION}a"
    tags ={
    		Type= "private"
  	}    
}

data "aws_iam_instance_profile" "prj_iam_profile" {
  name = "pf_EC2_SSM_S3_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
}
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

#--- Gets Security group with tag specified by var.VPC_SG_TAG
data "aws_security_group" "selected" {
  tags = {
    Name = "sg_ec2_public_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
  }
}


resource "aws_instance" "EC2_public" {
  ami           	= data.aws_ami.ubuntu.id
  
  instance_type 	= var.INSTANCE_TYPE
  count = 1
  subnet_id  = data.aws_subnet.selectedPublic.id 
  associate_public_ip_address = true
  #security_groups 	= ["${module.main-vpc.security_group.id}"]
  security_groups =[data.aws_security_group.selected.id]
   iam_instance_profile = data.aws_iam_instance_profile.prj_iam_profile.name
  key_name 			= var.KEY_NAME
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data       = data.template_file.script.rendered

  tags = {
    Owner        = var.OWNER
    Name         = "${var.PROJECTNAME}-u18-${var.ENV}_${tostring(count.index)}"
    Environmnent = var.ENV
    ResourceName = "aws_instance"
  }
}

/*
resource "aws_instance" "EC2_private" {
  ami           	= data.aws_ami.ubuntu.id
  count = "${length(var.private_subnets)}"
  instance_type 	= "t2.micro"
  subnet_id = "${element(aws_subnet.PLink-privatesubnet.*.id, count.index)}"

  #security_groups 	= ["${module.main-vpc.security_group.id}"]
  key_name 			= var.KEY_NAME
  
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data       = data.template_file.script.rendered

  tags = {
    Name         = "${var.PROJECTNAME}-u18-${var.ENV}_${tostring(count.index)}"
    Environmnent = var.ENV
  }
}
*/

data "template_file" "script" {
  template = file("script.tpl")
  vars = {
    anyvar = "Hello!"
  }
}

