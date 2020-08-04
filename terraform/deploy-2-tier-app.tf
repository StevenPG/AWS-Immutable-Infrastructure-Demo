// Configure provider, that is AWS region us-east-1
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

// Empty variable to hold the keyname so we can use it elsewhere
variable "key_name" {
  description = "what should we name our key? This is an example of input variable..."
}

// Deploy an RDS instance
resource "aws_db_instance" "pg_rds" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
}

// Output the RDS endpoint to us in case we want to access it directly
output "rds_endpoint" {
  value = aws_db_instance.pg_rds.endpoint
  description = "The RDS instance the app will communicate with."
}

// Generate a new public/private keypair. This is immutable infrastructure so
// we probably won't be SSHing in anyway.
resource "tls_private_key" "our_ec2_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Configure a keypair for the EC2 we're about to create
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.our_ec2_keypair.public_key_openssh
}

// Output the private key for us to use, this should be removed in theory
// the private key can be pulled from the state file at any time
output "ec2_private_key" {
  value = "${tls_private_key.our_ec2_keypair}"
  description = "The private key we can use to SSH into our newly generated EC2 instance."
}

// Auto-configure a security group, just for our VM (for now)
resource "aws_security_group" "ubuntu" {
  name        = "ubuntu-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "terraformed"
  }
}

// We could hard-code an AMI, but this is a good example of searching for the one!
// This sets a variable that we can use inside terraform, and we will use for our EC2
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

// Deploy a t2.micro EC2 instance
resource "aws_instance" "ubuntu" {
  key_name      = aws_key_pair.generated_key.key_name
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu"
  }

  vpc_security_group_ids = [
    aws_security_group.ubuntu.id
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("key")
    host        = self.public_ip
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.ubuntu} >> server.txt"
  }
}

resource "aws_eip" "ubuntu" {
  vpc      = true
  instance = aws_instance.ubuntu.id
}
