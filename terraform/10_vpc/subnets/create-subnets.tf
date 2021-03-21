variable vpc_id {}
variable ENV {}
variable PROJECTNAME {}
variable OWNER {}
variable region {}
variable subnet_list {}
variable availability_zone {}
variable tags {
	type = map(string)
}

locals {
  sregion = replace(var.region, "-", "")
}

variable noof-subnet-bits { default = 3 }


## Query VPC to Create Subnets - Yes, we can pass this as variable, instead of query this value. 
## But why pass 2 parameters if you can query :-)  
data "aws_vpc" "selected" {
    id = var.vpc_id
}

## Create public and private route-tables 
resource "aws_route_table" "crt" {
  count = 2 
  vpc_id = var.vpc_id
  tags = {
    Name = "rt-${var.ENV}-${var.PROJECTNAME}-${(count.index == 0 ? "public" : "private")}-${local.sregion}" 
    type = (count.index == 0 ? "public" : "private")
    Owner = var.OWNER
    Purpose = lookup(var.tags, "Purpose")
    Environment = var.ENV
  }
}

resource "aws_subnet" "services-subnets" {
    count = (length(var.subnet_list))*(length(var.availability_zone))
    vpc_id = data.aws_vpc.selected.id
    availability_zone = "${var.region}${var.availability_zone[count.index%length(var.availability_zone)]}"
    cidr_block = cidrsubnet(data.aws_vpc.selected.cidr_block, var.noof-subnet-bits, count.index)
    // first net in each zone will be public
    map_public_ip_on_launch = ((count.index < length(var.availability_zone)) ? true : false)
    tags = {
        Name = "sn-${var.ENV}-${var.PROJECTNAME}-${var.subnet_list[floor(count.index  / length(var.availability_zone))]}-${local.sregion}"
        Type = ((count.index < length(var.availability_zone)) ? "public" : "private")
        Owner = var.OWNER
        Purpose = lookup(var.tags, "Purpose")
        Environment = var.ENV
        
    }
}


resource "aws_route_table_association" "assign" {
    count = (length(var.subnet_list))*(length(var.availability_zone))
    subnet_id      = element(aws_subnet.services-subnets.*.id,count.index)
    route_table_id = ((count.index < length(var.availability_zone)) ? 
                         aws_route_table.crt.0.id : aws_route_table.crt.1.id)
}

output "public_subnet_ids" {
    value = slice(aws_subnet.services-subnets.*.id,0,length(var.availability_zone))
    //value = aws_subnet.services-subnets.*.id // slice(aws_subnet.services-subnets.*.id,0,1)
}
output "private_subnet_ids" {
    value = slice(aws_subnet.services-subnets.*.id,length(var.availability_zone),length(var.subnet_list)*length(var.availability_zone))
}
output "route_table_ids" {
    value = aws_route_table.crt.*.id
}


// Name = "${lookup(var.tags, "Purpose")}-${(count.index == 0 ? "public" : "private")}"
// route_table_id = "${var.subnet_list[1+(2*(count.index/(length(var.availability_zone))))] == "public" ? 
// var.route_tables[0] : var.route_tables[1]}"
// map_public_ip_on_launch = "${var.subnet_list[1+(2*(count.index/(length(var.availability_zone))))] == "public" ? true : false }"
// Name = "${lookup(var.tags, "Purpose")}-${var.subnet_list[2*(count.index/(length(var.availability_zone)))]}-${var.availability_zone[count.index%3]}"

