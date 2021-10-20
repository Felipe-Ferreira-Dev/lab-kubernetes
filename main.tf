provider "aws" {
  region = "us-east-1"
}


resource "aws_instance" "k8s_proxy" {
  ami           = "ami-09e67e426f25ce0d7"
  key_name      = "key-dev-tf"
  subnet_id     = "subnet-0b6ee665d5b518339"
  instance_type = "t2.micro"
  root_block_device {
    encrypted   = true
    volume_size = 20
  }

  tags = {
    Name = "k8s-haproxy"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos.id}"]
  depends_on = [
    aws_instance.workers,
  ]
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-09e67e426f25ce0d7"
  instance_type               = "t2.large"
  key_name                    = "key-dev-tf"
  subnet_id                   = "subnet-0b6ee665d5b518339"
  associate_public_ip_address = true
  root_block_device {
    encrypted   = true
    volume_size = 20
  }
  count = 3
  tags = {
    Name = "k8s-master-ffaihdw-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_master.id}"]
}

resource "aws_instance" "k8s_workers" {
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
    Name = "k8s-node-ffaihdw-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_workers.id}"]
  count                  = 3
}


resource "aws_security_group" "acessos_master" {
  name        = "acessos_master"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-080da39cf7b8a7fdc"

  ingress = [
    {
      cidr_blocks = [
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
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups = [
        #"${aws_security_group.acessos_workers.id}",
      ]
      self    = false
      to_port = 65535
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
      cidr_blocks = [
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
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups = [
       #"${aws_security_group.acessos_master.id}",
      ]
      self    = false
      to_port = 65535
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
resource "aws_security_group" "acessos" {
  name        = "k8s-acessos"
  description = "acessos inbound traffic"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null,
      description      = "Libera dados da rede interna"
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups = [
        "${aws_security_group.acessos_master.id}",
      ]
      self    = false
      to_port = 0
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = [],
      prefix_list_ids  = null,
      security_groups  = null,
      self             = null,
      description      = "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "allow_ssh"
  }
}


# terraform refresh para mostrar o ssh
output "k8s-masters" {
  value = [
    for key, item in aws_instance.master :
      "k8s-master ${key+1} - ${item.private_ip}  - ssh -i ~/.ssh/id_rsa_itau ubuntu@${item.public_dns}"
  ]
}


output "output-k8s_workers" {
  value = [
    for key, item in aws_instance.k8s_workers :
      "k8s-workers ${key+1} - ${item.private_ip}  - ssh -i ~/.ssh/id_rsa_itau ubuntu@${item.public_dns}"
  ]
}
output "output-k8s_proxy" {
  value = [
    "k8s_proxy - ${aws_instance.k8s_proxy.private_ip} - ssh -i ~/.ssh/id_rsa_itau ubuntu@${aws_instance.k8s_proxy.public_dns}"
  ]
}
