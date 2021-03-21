

data "aws_subnet_ids" "selected" {
    vpc_id = data.aws_vpc.selected.id
    tags ={
      Environment = var.ENV
  	}    
}
data "aws_subnet" "selected" {
  for_each = data.aws_subnet_ids.selected.ids
  id       = each.value
}
resource "aws_iam_role" "eks_cluster" {
  name = "iamrole_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}"
assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "aws_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_iam_role_policy_attachment" "aws_eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "eks_cluster" {
  name        = "sg_eks_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}"
  description = "Cluster communication with worker nodes"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "sg_eks_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}"
    Owner=var.OWNER
	Terraform = "true"
    Environment = var.ENV
    ResourceName = "aws_security_group"
  }
}
resource "aws_security_group" "eks_nodes" {
  name        = "sg_nodes_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}" 
  description = "Security group for all nodes in the cluster"
  
  vpc_id = data.aws_vpc.selected.id
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name                                        = "sg_nodes_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}" 
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    Owner=var.OWNER
	Terraform = "true"
    Environment = var.ENV
    ResourceName = "aws_security_group"
  }
}
resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}
resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id]
    endpoint_private_access = local.endpoint_private_access
    endpoint_public_access  = local.endpoint_public_access
    subnet_ids = data.aws_subnet_ids.selected.ids
  }
  tags = {
    Name = "eks_cluster-${var.PROJECTNAME}-${var.ENV}-${local.sregion}"
    Owner=var.OWNER
	Terraform = "true"
    Environment = var.ENV
    ResourceName = "aws_eks_cluster"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_cluster_policy,
    aws_iam_role_policy_attachment.aws_eks_service_policy
  ]
}