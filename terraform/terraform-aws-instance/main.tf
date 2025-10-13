resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "${var.region}a" # Or choose dynamically
  tags = {
    Name = "${var.project_name}-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.project_name}-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Or restrict to specific IPs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-allow-ssh"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_pair_name
  public_key = var.public_key_openssh
}

# This data source finds the latest Ubuntu 24.04 LTS AMI
# It filters by the most recent creation date, owner (Canonical), and name.
data "aws_ami" "default" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.instance_image]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical's AWS account ID
  owners = ["099720109477"]
}

resource "aws_instance" "managers" {
  count         = var.manager_count
  ami           = data.aws_ami.default
  instance_type = var.manager_instance_size
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true


  tags = {
    Name    = "${var.project_name}-manager-${count.index}"
    Role    = "manager"
    Project = var.project_name
  }
}

resource "aws_instance" "nodes" {
  count         = var.worker_count
  ami           = data.aws_ami.default
  instance_type = var.worker_instance_size
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name    = "${var.project_name}-node-${count.index}"
    Role    = "node"
    Project = var.project_name
  }
}
