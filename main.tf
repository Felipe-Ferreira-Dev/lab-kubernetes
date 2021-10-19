provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ou ["099720109477"] ID master com permissão para busca

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"] # exemplo de como listar um nome de AMI - 'aws ec2 describe-images --region us-east-1 --image-ids ami-09e67e426f25ce0d7' https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  }
}

resource "aws_instance" "maquina_master" {
  ami                         = "ami-09e67e426f25ce0d7"
  instance_type               = "t2.medium"
  key_name                    = "key-dev-tf"
  subnet_id                   = "subnet-0b6ee665d5b518339"
  associate_public_ip_address = true
  root_block_device {
    encrypted   = true
    volume_size = 20
  }
  tags = {
    Name = "k8s-master-ffaihdw"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_master.id}"]
  depends_on = [
    aws_instance.workers,
  ]
}

resource "aws_instance" "workers" {
  ami                         = "ami-09e67e426f25ce0d7"
  instance_type               = "t2.micro"
  key_name                    = "key-dev-tf"
  subnet_id                   = "subnet-0b6ee665d5b518339"
  associate_public_ip_address = true
  root_block_device {
    encrypted   = true
    volume_size = 20
  }
  tags = {
    Name = "k8s-node-ffaihdw-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_workers.id}"]
  count                  = 2
}


resource "aws_security_group" "acessos_master" {
  name        = "acessos_master"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-080da39cf7b8a7fdc"

  ingress = [
       {
     cidr_blocks      = [
           "0.0.0.0/0",
        ]
       description      = "SSH from VPC"
       from_port        = 22
       ipv6_cidr_blocks = []
       prefix_list_ids  = []
       protocol         = "tcp"
       security_groups  = []
       self             = false
       to_port          = 22
      },
      {
         cidr_blocks      = []
         description      = ""
         from_port        = 0
         ipv6_cidr_blocks = []
         prefix_list_ids  = []
         protocol         = "tcp"
         security_groups  = [
             "sg-0b844b8de4544cf09"
          ]
         self             = false
         to_port          = 65535
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups : null,
      self : null,
      description : "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "acessos_master"
  }
}


resource "aws_security_group" "acessos_workers" {
  name        = "acessos_workers"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-080da39cf7b8a7fdc"
  ingress = [
     {
     cidr_blocks      = [
           "0.0.0.0/0",
        ]
       description      = "SSH from VPC"
       from_port        = 22
       ipv6_cidr_blocks = []
       prefix_list_ids  = []
       protocol         = "tcp"
       security_groups  = []
       self             = false
       to_port          = 22
      },
      {
         cidr_blocks      = []
         description      = ""
         from_port        = 0
         ipv6_cidr_blocks = []
         prefix_list_ids  = []
         protocol         = "tcp"
         security_groups  = [
             "sg0575b2e79ee6ebd06",
          ]
         self             = false
         to_port          = 65535
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups : null,
      self : null,
      description : "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "acessos_workers"
  }
}


# terraform refresh para mostrar o ssh
output "maquina_master" {
  value = [
    "master - ${aws_instance.maquina_master.public_ip} - ssh -i ~/.ssh/id_rsa_itau ubuntu@${aws_instance.maquina_master.public_dns}"
  ]
}

# terraform refresh para mostrar o ssh
output "aws_instance_e_ssh" {
  value = [
    for key, item in aws_instance.workers :
    "worker ${key + 1} - ${item.public_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${item.public_dns}"
  ]
}
