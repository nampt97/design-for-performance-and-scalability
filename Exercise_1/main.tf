provider "aws" {
  region = "us-east-1"
}


# Provision 4 AWS t2.micro EC2 instances named Udacity T2
resource "aws_instance" "udacity-t2" {
  ami = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"
  subnet_id = "subnet-0391d66220452d6c1"
  count = 4
  tags = {
    Name = "Udacity T2"
  }
}
