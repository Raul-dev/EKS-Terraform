

resource "aws_iam_role" "prj_iam_role" {
  name = "EC2_SSM_S3_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      Owner = var.OWNER
  }
}

output "RoleName" {
  value = aws_iam_role.prj_iam_role.name
}

resource "aws_iam_instance_profile" "prj_iam_profile" {
  name = "pf_EC2_SSM_S3_${var.PROJECTNAME}_${var.ENV}_${local.sregion}"
  role = aws_iam_role.prj_iam_role.name
}

output "MasterProfile" {
  value = aws_iam_instance_profile.prj_iam_profile.name
}

resource "aws_iam_role_policy_attachment" "s3_assume_role_ath" {
    role       = aws_iam_role.prj_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_assume_role_ath" {
    role       = aws_iam_role.prj_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    
}


