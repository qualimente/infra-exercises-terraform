// Add a Postgres DB using RDS - START

resource "aws_security_group" "db" {
  name   = "db-${var.name}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.internal_web.id}"]
  }
}

module "db" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-rds.git?ref=v1.4.0"

  identifier = "${local.exercise_app_name}"

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

  password = "${var.db_pass}"
  port     = "5432"

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = "${local.base_tags}"

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

// Add a Postgres DB using RDS - END

