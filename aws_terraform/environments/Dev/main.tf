provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/home/manpreetsingh/.aws/credentials"
  profile = "default"
}

module "availability_zones" {
  source = "../../modules/availability_zones"
}

module "VPC" {
    source = "../../modules/vpc"
    vpc_name = "dev_vpc"
    vpc_cidr = "10.12.0.0/16"
}

module "internet_gateway" {
    source = "../../modules/internet_gateway"
    vpc_id = module.VPC.vpc_id
    
}

module "public_subnet" {
  source = "../../modules/subnet"
  vpc_id = module.VPC.vpc_id
  cidr_block = "10.12.1.0/24"
  name = "public_subnet"
  availability_zone_id = module.availability_zones.availability_zones[0]
  map_public_ip_on_launch = true
}


module "private_subnet" {
  source = "../../modules/subnet"
  vpc_id = module.VPC.vpc_id
  cidr_block = "10.12.2.0/24"
  name = "private-subnet"
  availability_zone_id = module.availability_zones.availability_zones[1]
  map_public_ip_on_launch = false
}

module "route_table1" {
    source = "../../modules/route_table"
    vpc_id = module.VPC.vpc_id
    name = "Public_Route_Table"
}

module "route_table_public_sub_assoc" {
  source = "../../modules/route_table_assoc"
  subnet = true
  subnet_id = module.public_subnet.subnet_id
  route_table_id = module.route_table1.route_table_id
}

module "route_1_sub1" {
  source = "../../modules/table_route"
  route_table_id = module.route_table1.route_table_id
  ngw = false
  dest_cidr = "0.0.0.0/0"
  gateway_id = module.internet_gateway.gateway_id
}

module "route_table2" {
    source = "../../modules/route_table"
    vpc_id = module.VPC.vpc_id
    name = "Private Route Table"
}

module "route_table_private_sub_assoc" {
  source = "../../modules/route_table_assoc"
  subnet_id = module.private_subnet.subnet_id
  subnet = true
  route_table_id = module.route_table2.route_table_id
}

module "private_sub_route" {
  source = "../../modules/table_route"
  route_table_id = module.route_table2.route_table_id
  ngw = true
  dest_cidr = "0.0.0.0/0"
  nat_gateway_id = module.nat_gateway.nat_gateway_id
}


module "nat_gateway" {
    source = "../../modules/nat_gateway"
    eip_id = module.elastic_ip.eip_id
    subnet_id = module.public_subnet.subnet_id
}

module "elastic_ip" {
  source = "../../modules/eip"
  name = "NAT_Gateway_Elastic_IP"
}

module "ALB_security_group" {
  source = "../../modules/security_group"
  name = "ALB_Security_Group"
  description = "security group for application load balancer"
  vpc_id = module.VPC.vpc_id
  
}

module "ALB_Security_Group_Rule1" {
  source = "../../modules/security_group_rule"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ALB_security_group.security_group_id

}

module "ALB_Security_Group_Rule2" {
  source = "../../modules/security_group_rule"
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ALB_security_group.security_group_id

}

module "server_security_group" {
  source = "../../modules/security_group"
  name = "Server_Security_Group"
  description = "Security group for servers in private subnet"
  vpc_id = module.VPC.vpc_id
  
}

module "server_security_group_rule1" {
  source = "../../modules/server_sg_rule"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  security_group_id = module.server_security_group.security_group_id
  source_security_group_id = module.ALB_security_group.security_group_id
}

module "server_security_group_rule2" {
  source = "../../modules/server_sg_rule"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = module.server_security_group.security_group_id
  source_security_group_id = module.Jumphost_security_group.security_group_id
}


module "Jumphost_security_group" {
  source = "../../modules/security_group"
  name = "Jumphost_Security_Group"
  description = "security group for jumphost"
  vpc_id = module.VPC.vpc_id
  
}

module "bastion_sg_rule1" {
  source = "../../modules/security_group_rule"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = module.Jumphost_security_group.security_group_id
  cidr_blocks = ["73.150.47.189/32"]
}

module "key_pair" {
  source = "../../modules/key_pair"
  name = "jumphost"
  public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc8f0IYs0nrUFo8nP1IMf/LIzvwGDMRSU/h4QXnohb+Q+G0zlYc76axlC60DVZOg3jXY5c6Vky5pHN7yNeMahTncM5WER8uSwkYVImznq3CyZQatNdj12flRP6lULb2oMIaBNrP/VhfYqwVVL2kDwGpHylpE3WCCoYiwJiCJezRT8SCGURaEowWuNxHlgJfVnzkSnG1hlEUmqlW6Y8ZS9W55LKJrqOnjx4jMH93FP3IZWSnCPM2LofD6rF7sep8FnQzDmTNsy02EXEJ2C0oFgiwOl5qPgHGGH65D0imZxe/bZFeCHx8Rj2sl3tb9Jo8A4vQs9k2LgFUVLiikORGjE/P5nrHsnR4uTTySuSl0zg1MGXpgXbZLn9dpLCGTjk5k5OMh23RLBoJqjBKabNd2ZdTaUCsgnizOhDi5lOzbVG5+LbkK9HYgcqS9P7h0udbHSke77uO7LqU5t4mI5hxtHsS3B8xmzXGD4qqo6mQQaJaOCcgnzyOv3k0gbL5hCiiL8= manpreetsingh@Manpreets-MacBook-Pro.local"
}

module "Bastion_Jumphost" {
  source = "../../modules/ec2_ssh"
  subnet_id = module.public_subnet.subnet_id
  name = "Bastion_Host"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.Jumphost_security_group.security_group_id]
  key_name = "jumphost"

}

module "WebServer1_Dev" {
  source = "../../modules/ec2_ssh"
  subnet_id = module.private_subnet.subnet_id
  name = "My_WebServer1_Dev"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.server_security_group.security_group_id]
  key_name = "jumphost"
}

module "WebServer2_Dev" {
  source = "../../modules/ec2_ssh"
  subnet_id = module.private_subnet.subnet_id
  name = "My WebServer 2 Dev main"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.server_security_group.security_group_id]
  key_name = "jumphost"

}
module "WebServer3_Dev" {
  source = "../../modules/ec2_ssh"
  subnet_id = module.private_subnet.subnet_id
  name = "My WebServer 3 Dev main"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.server_security_group.security_group_id]
  key_name = "jumphost"

}

module "Alb_Target_Group" {
  source = "../../modules/target_group"
  port = 80  //port which target is listening on
  protocol = "HTTP"  //protocol to send traffic to target
  target_type = "instance"
  vpc_id = module.VPC.vpc_id
} 

module "Alb_Target_Attachment1" {
  source = "../../modules/target_group_assoc"
  target_group_arn = module.Alb_Target_Group.target_group_arn
  target_id = module.WebServer1_Dev.instance_id
  port = 80
}

module "Alb_Target_Attachment2" {
  source = "../../modules/target_group_assoc"
  target_group_arn = module.Alb_Target_Group.target_group_arn
  target_id = module.WebServer2_Dev.instance_id
  port = 80
}

module "Alb_Target_Attachment3" {
  source = "../../modules/target_group_assoc"
  target_group_arn = module.Alb_Target_Group.target_group_arn
  target_id = module.WebServer3_Dev.instance_id
  port = 80
}

module "Application_Load_Balancer" {
  source = "../../modules/alb"
  name = "ALB"
  internal = false
  load_balancer_type = "application"
  security_groups = [module.ALB_security_group.security_group_id]
  subnets = [module.public_subnet.subnet_id,module.private_subnet.subnet_id]
}

module "alb_listner" {
  source = "../../modules/alb_listener"
  load_balancer_arn = module.Application_Load_Balancer.alb_arn
  port = 80
  protocol = "HTTP"
  type= "forward"
  target_group_arn = module.Alb_Target_Group.target_group_id
  
}



