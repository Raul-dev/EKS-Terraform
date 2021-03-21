#-- Creates SSH key to provision server
resource "aws_key_pair" "deployer" {
  key_name   = var.KEY_NAME
  public_key = file("${var.KEYPATH}${var.KEY_NAME}.pub")
  
  
  tags = {
    Name = "Key {var.PROJECTNAME}"
    Owner = var.OWNER
    Purpose = "EC2 ssh key"
  }
}
