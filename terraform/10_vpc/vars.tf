variable "KEYPATH"{}
variable "KEY_NAME" {}
variable "ENV" {}
variable "PROJECTNAME"  {}
variable "INSTANCE_TYPE" {}
variable "INGRES_SCIDR_BLOCK" {}
variable "OWNER" {}
variable "CIDR_BLOCK" {}
variable "BACKENDNAME" {}



variable availability_zone {
    type = list(string)
    default = ["a","b","c"]
}

variable subnet_list { 
  type = list(string)
  default = ["public","private"]
}




########################### Autoscale Config ################################

variable "max_instance_size" {
default = 3
  description = "Maximum number of instances in the cluster"
}

variable "min_instance_size" {
default = 1
  description = "Minimum number of instances in the cluster"
}

variable "desired_capacity" {
default = 1
  description = "Desired number of instances in the cluster"
}