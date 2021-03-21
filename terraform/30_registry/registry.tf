

# Elastic Container Registry Repository
resource "aws_ecr_repository" "imgrepo" {
  name = "${var.REPO_NAME[count.index]}-${var.ENV}"
  count = length(var.REPO_NAME)
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = {
    Name        = "REP_${var.REPO_NAME[count.index]}_${var.PROJECTNAME}_${var.ENV}"
    Terraform   = "true"
    Environment = var.ENV 
    Owner       = var.OWNER	
    ResourceName = "aws_ecr_repository"
  }
}