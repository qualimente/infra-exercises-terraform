variable "region" {
  description = "AWS region to use"
  default     = "us-east-1"
}

variable "name" {
  default = "exercise-skuenzli"
}

variable "vpc_id" {
  default = "vpc-58a29221"
}

data "aws_vpc" "default_vpc" {
  id = "${var.vpc_id}"
}

data "aws_subnet_ids" "default_vpc" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "public_web" {
  name        = "public-web"
  description = "Permits http and https access from the public Internet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_ssh" {
  name        = "public-ssh"
  description = "Permit ssh access from the public Internet"
  vpc_id      = "${var.vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal_web" {
  name        = "internal-web"
  description = "Permits http access from the sources in the VPC"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.default_vpc.cidr_block}"]
  }
}

resource "aws_security_group" "outbound" {
  name        = "outbound"
  description = " permits access from the VPC to the Internet"
  vpc_id      = "${var.vpc_id}"

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "exercise" {
  key_name   = "${var.name}"
  public_key = "${file("exercise.id_rsa.pub")}"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = "list"

  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
}

variable "centos7_amis" {
  description = "CentOS 7 AMI IDs, keyed by region"
  type        = "map"

  default = {
    us-east-1 = "image-1234"
    us-east-2 = "image-2341"
    us-west-1 = "image-3412"
    us-west-2 = "image-4123"
  }
}

resource "aws_instance" "app" {
  count         = "1"
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-fad25980"

  #ami = "${var.centos7_amis[var.region]}"

  user_data = "${file("app.yml")}"
  # The name of our SSH keypair we created above.
  key_name                    = "${aws_key_pair.exercise.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    "${aws_security_group.public_ssh.id}",
    "${aws_security_group.internal_web.id}",
    "${aws_security_group.outbound.id}",
  ]
  availability_zone = "${var.availability_zones[count.index]}"
  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${element(data.aws_subnet_ids.default_vpc.ids, count.index)}"
  tags {
    Name = "${var.name}-${count.index}"
  }
}

resource "aws_elb" "web" {
  name = "${var.name}"

  subnets = ["${data.aws_subnet_ids.default_vpc.ids}"]

  security_groups = [
    "${aws_security_group.public_web.id}",
    "${aws_security_group.outbound.id}",
  ]

  instances = ["${aws_instance.app.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 15
  }
}


output "lb.web.dns_name" {
  value = "${aws_elb.web.dns_name}"
}
