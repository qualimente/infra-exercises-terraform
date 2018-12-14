// Define namespace and network to use for project - START

variable "name" {
  description = "a name/userid to use for namespacing the resources created in this exercise, e.g. jsmith"
  default = "<your name>"
}

variable "vpc_id" {
  default = "vpc-58a29221"
}

// Define namespace and network to use for project - END


// Resolve existing network resources - START

data "aws_vpc" "default_vpc" {
  id = "${var.vpc_id}"
}

data "aws_subnet_ids" "default_vpc" {
  vpc_id = "${var.vpc_id}"
}

// Resolve existing network resources - END


// Create Firewall Rules to Permit Access - START

resource "aws_security_group" "public_web" {
  name        = "public-web-${var.name}"
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
  name        = "public-ssh-${var.name}"
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
  name        = "internal-web-${var.name}"
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
  name        = "outbound-${var.name}"
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

// Create Firewall Rules to Permit Access - END

// Create an EC2 instance - START

data "aws_ami" "amazon_ecs_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-*.i-amazon-ecs-optimized",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

locals {
  exercise_app_name = "exercise-${var.name}"
}

resource "aws_key_pair" "exercise" {
  key_name   = "${local.exercise_app_name}"
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

variable "db_pass" {
  default = "mypass27"
  description = "Password to use for DB"
}

data "template_file" "init" {
  template = "${file("${path.module}/nginx.yml.tpl")}"
  
  //uncomment serviceapi cloud-init once db instantiated
  //template = "${file("${path.module}/init.yml.tpl")}"

  //uncomment db module address output once db instantiated
  vars {
    //postgres_address = "${module.db.this_db_instance_address}"
    //postgres_password = "${var.db_pass}"
  }
}


resource "aws_instance" "app" {
  count         = "1"
  instance_type = "t2.micro"

  ami = "${data.aws_ami.amazon_ecs_linux.id}"

  user_data = "${data.template_file.init.rendered}"
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
    Name = "${local.exercise_app_name}-${count.index}"
  }
}

// Create an EC2 instance - END

// Create an Auto Scaling Group to run the application - START

module "asg" {
  //use a module for the official Terraform Registry
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "2.9.0"

  name = "${local.exercise_app_name}"

  instance_type   = "t2.micro"
  
  image_id        = "${data.aws_ami.amazon_ecs_linux.id}"

  user_data = "${data.template_file.init.rendered}"
  key_name = "${aws_key_pair.exercise.id}"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "${local.exercise_app_name}"

  security_groups = [
      "${aws_security_group.public_ssh.id}",
      "${aws_security_group.internal_web.id}",
      "${aws_security_group.outbound.id}",
    ]

  load_balancers  = ["${aws_elb.web.id}"]

  root_block_device = [
    {
      volume_size = "20"
      volume_type = "gp2"
      delete_on_termination = true
    },
  ]

  # Auto scaling group
  asg_name                  = "${local.exercise_app_name}"
  vpc_zone_identifier       = ["${data.aws_subnet_ids.default_vpc.ids}"]
  health_check_type         = "EC2"
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 2
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "training"
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = "${var.name}"
      propagate_at_launch = true
    },
  ]
}
// Create an Auto Scaling Group to run the application - END


// Create an ELB - START

resource "aws_elb" "web" {
  name = "${local.exercise_app_name}"

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

// Create an ELB - END


// Output Location of ELB and App Server - START

output "lb.web.dns_name" {
  value = "${aws_elb.web.dns_name}"
}

output "app.web.dns_name" {
  value = "${aws_instance.app.public_dns}"
}

// Output Location of ELB and App Server - END