provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins-vpc"
  }
}
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "jenkins-subnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "jenkins-rt"
  }
}
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}
resource "aws_instance" "jenkins_server" {
  ami           = "ami-03f4878755434977f" # Ubuntu 22.04 LTS (ap-south-1)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Update packages
              apt update -y

              # Install Java
              apt install fontconfig openjdk-17-jre -y

              # Add Jenkins Key
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
              | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg

              # Add Jenkins Repo
              echo "deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" \
              > /etc/apt/sources.list.d/jenkins.list

              # Install Jenkins
              apt update -y
              apt install jenkins -y

              # Start Jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "jenkins-server"
  }
}
