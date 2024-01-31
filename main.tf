#########################
## Create VPC resource ##
#########################
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "${var.project}-${var.env}-public-subnet"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "${var.project}-${var.env}-public-routetbl"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#########################
## Create EC2 Instance ##
#########################
data "aws_ssm_parameter" "amazonlinux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "sample" {
  ami                         = data.aws_ssm_parameter.amazonlinux_2023.value
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  instance_type               = "m7i.large"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true # attach public ip address
  iam_instance_profile        = aws_iam_instance_profile.ssm_role.name
  user_data                   = file("userdata.sh")

  tags = {
    Name = "${var.project}-${var.env}-instance"
  }
}

resource "aws_security_group" "ec2" {
  name   = "${var.project}-${var.env}-ec2-sg"
  vpc_id = aws_vpc.example.id
  ingress {
    from_port   = 8211
    to_port     = 8211
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "ssm_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ssm_role" {
  name = "EC2RoleforSSM"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role" "ssm_role" {
  name               = "EC2RoleforSSM"
  assume_role_policy = data.aws_iam_policy_document.ssm_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_role" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
