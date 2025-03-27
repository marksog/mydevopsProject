# 1 creating a VPC

resource "aws_vpc" "comp_network" {
    cidr_block = var.vpc_cidr
    instance_tenancy = var.instance_tenancy
    enable_dns_support = true
    tags = var.tag_overlay
}

# 2 creating subnets
# public subnets
resource "aws_subnet" "public_subnet_A" {
    vpc_id = aws_vpc.comp_network.id
    cidr_block = var.public_subnet_a_cidr
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags = merge(var.tag_overlay, { Name = "PublicSubnetA" })
}

resource "aws_subnet" "public_subnet_B" {
    vpc_id = aws_vpc.comp_network.id
    cidr_block = var.public_subnet_b_cidr
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    tags = merge(var.tag_overlay, { Name = "PublicSubnetB" }) 
}

# private subnets
resource "aws_subnet" "private_subnet_A" {
    vpc_id = aws_vpc.comp_network.id
    cidr_block = var.private_subnet_a_cidr
    availability_zone = "us-east-1a"
    tags = merge(var.tag_overlay, { Name = "PrivateSubnetA" })
}

resource "aws_subnet" "private_subnet_B" {
    vpc_id = aws_vpc.comp_network.id
    cidr_block = var.private_subnet_b_cidr
    availability_zone = "us-east-1b"
    tags = merge(var.tag_overlay, { Name = "PrivateSubnetB" })
}

# 3 creating IGW and NATGW
resource "aws_internet_gateway" "comp_igw" {
    vpc_id = aws_vpc.comp_network.id
    tags = merge(var.tag_overlay, { Name = "IGW" })
}

# create and elastic ip
resource "aws_eip" "nat_eip" {
    associate_with_private_ip = null
}

# associate or attach eip to natgw
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet_A.id
    tags = { Name = "NATGW" }
}

# 4 Creating Public route tables
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.comp_network.id
    route {
        cidr_block = var.pubrt_cidrblock
        gateway_id = aws_internet_gateway.comp_igw.id
    }
    tags = { Name = "PublicRT" }
}

# 5 Creating Private route tables
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.comp_network.id
    route {
        cidr_block = var.privrt_cidrblock
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
    tags = { Name = "PrivateRT" }
}

# 6 Associate route tables with subnets
resource "aws_route_table_association" "private_A__rt_association" {
    subnet_id = aws_subnet.private_subnet_A.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_B_rt_association" {
    subnet_id = aws_subnet.private_subnet_B.id
    route_table_id = aws_route_table.private_rt.id
}

# 7 just an IAM role if needed
resource "aws_iam_role" "ec2_role" {
    name = "ec2_role"
    assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "ec2_trust" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

# 8 attaching this policy (just for fun to see how it works)
resource "aws_iam_role_policy_attachment" "ec2_attach" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile"
    role = aws_iam_role.ec2_role.name  
}

# setting up security groups
resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    vpc_id = aws_vpc.comp_network.id
    description = "Allow HTTP and HTTPS traffic tp ALB"

    ingress {
        description = "HTTP from anywhere"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp" 
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = { Name = "ALBSG" }
}

resource "aws_security_group" "ec2_sg" {
    name = "ec2_sg"
    description = "allow http traffic from ALB"
    vpc_id = aws_vpc.comp_network.id
    ingress {
        description = "HTTP from ALB"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }
    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      name = "EC2SG"
    }
  
}
# shoot i notice i also need key pair to ssh into the instance
resource "tls_private_key" "generated_key_with_terraform" {
    algorithm = "RSA"
    rsa_bits  = 4096 
}

resource "aws_key_pair" "generated_key" {
    key_name   = "terrafrom-generated_key"
    public_key = tls_private_key.generated_key_with_terraform.public_key_openssh
  
}
#save the key

resource "local_file" "private_key_pem" {
    content = tls_private_key.generated_key_with_terraform.private_key_pem
    filename = "${path.module}/generated_key.pem"
    file_permission = "0400"
}

# setting up Load balancer 2 for public subnet, 2 for private subnet and target groups 
# typically will need one per environment just playing around with it.check 

# ALB for public subnet A
resource "aws_lb" "public_alb_A" {
    name = "public-alb-A"
    load_balancer_type = "application"
    subnets = [
        aws_subnet.public_subnet_A.id,
        aws_subnet.public_subnet_B.id
    ]
    security_groups = [aws_security_group.alb_sg.id]
    tags = {Name = "PublicALB-A"}
}


# ALB target group A for public subnet A
resource "aws_lb_target_group" "public_alb_target_A" {
    name = "public-alb-target-A"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.comp_network.id
    health_check {
        path = "/"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
    tags = {Name = "PublicALB-Target-A"}
}

# creating 4 servers behind this LB
resource "aws_instance" "public_server_A" {
    ami = "ami-0c55b159cbfafe1f0"
    count = 4
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_A.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    key_name = aws_key_pair.generated_key.key_name
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    tags = {Name = "PublicServer-A"}
    associate_public_ip_address = true
    user_data = <<-EOF
        #!/bin/bash
    yum install -y httpd
    echo "<h1>Hello from \$(hostname)</h1>" > /var/www/html/index.html
    echo "<p>Subnet: PublicSubnet1</p>" >> /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF
}

resource "aws_lb_target_group_attachment" "attach_public_A" {
    target_group_arn = aws_lb_target_group.public_alb_target_A.arn
    target_id = aws_instance.public_server_A[count.index].id
    depends_on = [aws_lb.public_alb_A]
    port = 80
    count = 4
}

# ALB for public subnet B
resource "aws_lb" "public_alb_B" {
    name = "public-alb-B"
    load_balancer_type = "application"
    subnets = [
        aws_subnet.public_subnet_A.id,
        aws_subnet.public_subnet_B.id
    ]
    security_groups = [aws_security_group.alb_sg.id]
    tags = {Name = "PublicALB-B"}
}


# ALB target group A for public subnet A
resource "aws_lb_target_group" "public_alb_target_B" {
    name = "public-alb-target-A"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.comp_network.id
    health_check {
        path = "/"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
    tags = {Name = "PublicALB-Target-B"}
}

# creating 4 servers behind this LB
resource "aws_instance" "public_server_B" {
    ami = "ami-0c55b159cbfafe1f0"
    count = 4
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_B.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    key_name = aws_key_pair.generated_key.key_name
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    tags = {Name = "PublicServer-B"}
    associate_public_ip_address = true
    user_data = <<-EOF
        #!/bin/bash
    yum install -y httpd
    echo "<h1>Hello from \$(hostname)</h1>" > /var/www/html/index.html
    echo "<p>Subnet: PublicSubnet1</p>" >> /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF
}

resource "aws_lb_target_group_attachment" "attach_public_B" {
    target_group_arn = aws_lb_target_group.public_alb_target_B.arn
    target_id = aws_instance.public_server_A[count.index].id
    depends_on = [aws_lb.public_alb_B]
    port = 80
    count = 4
}

#### i only did for 2 public subnets but you get the idea