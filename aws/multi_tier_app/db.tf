resource "aws_security_group" "db" {
  name = "db"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "5432"
    to_port = "5432"
    protocol = "tcp"
    security_groups = [ "${aws_security_group.internal_web.id}"]
  }
}

#####
# DB
#####
module "db" {
  #source = "../../../"
  source = "git@github.com:terraform-aws-modules/terraform-aws-rds.git?ref=v1.4.0"

  identifier = "exercise"

  engine            = "postgres"
  engine_version    = "9.6.3"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<accound id>:key/<kms key id>"
  name = "exercise"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "exercise"

  password = "mypass27"
  port     = "5432"

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "platform"
    Environment = "exercise"
  }

  # DB subnet group
  subnet_ids = ["${data.aws_subnet_ids.default_vpc.ids}"]

  # DB parameter group
  family = "postgres9.6"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "exercise"
}

output "db.web.address" {
  value = "${module.db.this_db_instance_address}"
}

output "db.web.endpoint" {
  value = "${module.db.this_db_instance_endpoint}"
}

