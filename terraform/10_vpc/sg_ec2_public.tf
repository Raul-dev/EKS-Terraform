

# ECS Instance Security group
resource "aws_security_group" "prj_public_sg" {
  name = "sg_ec2_public_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
  description = "sg_ec2_public_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
  vpc_id = aws_vpc.customvpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
	cidr_blocks = var.INGRES_SCIDR_BLOCK
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
	cidr_blocks = var.INGRES_SCIDR_BLOCK
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
	cidr_blocks = var.INGRES_SCIDR_BLOCK
  }

  egress {
    # allow all traffic to private SN
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_public_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
    Owner=var.OWNER
	  Terraform = "true"
    Environment = var.ENV
  }
}