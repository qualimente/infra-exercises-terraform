// Instantiate a minimal version of the module for testing
resource "random_id" "testing_suffix" {
  byte_length = 4
}

locals {
  name = "${var.name}-${random_id.testing_suffix.hex}"
}

data "aws_vpc" default {
  default = true
}

resource "tls_private_key" "test_minimal" {
  algorithm = "RSA"
}

resource "local_file" "test_ssh_public_key" {
  content  = "${tls_private_key.test_minimal.public_key_openssh}"
  filename = "${path.module}/id_rsa.test_minimal.pub"
}

resource "local_file" "test_ssh_private_key" {
  content  = "${tls_private_key.test_minimal.private_key_pem}"
  filename = "${path.module}/id_rsa.test_minimal.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }
}

module "it_minimal" {
  //instantiate multi_tier_app module for a minimal integration test
  source = "../../../"

  name   = "${local.name}"
  vpc_id = "${data.aws_vpc.default.id}"

  app_server_public_key = "${local_file.test_ssh_public_key.content}"
}

module "it_minimal_from_file" {
  //instantiate multi_tier_app module for a minimal integration test
  source = "../../../"

  name   = "${local.name}-key-file"
  vpc_id = "${data.aws_vpc.default.id}"

  #app_server_public_key_file = "/Users/skuenzli/.ssh/id_rsa.pub"
  #app_server_public_key_file = "${local_file.test_ssh_public_key.filename}"
  #app_server_public_key_file = "${path.module}/id_rsa.test_minimal.pub"
  app_server_public_key_file = "/module/test/fixtures/minimal/id_rsa.test_minimal.pub"
}

variable "name" {
  type = "string"
}

output "testing_suffix_hex" {
  value = "${random_id.testing_suffix.hex}"
}

output "multi_tier_app.name" {
  value = "${local.name}"
}

output "multi_tier_app.lb.web.dns_name" {
  value = "${module.it_minimal.lb.web.dns_name}"
}

output "multi_tier_app.app.web.dns_name" {
  value = "${module.it_minimal.app.web.dns_name}"
}

output "multi_tier_app.app.asg.name" {
  value = "${module.it_minimal.app.asg.name}"
}

output "terraform_state" {
  description = "The path to the Terraform state file; used in the state_file control"
  value       = "${path.cwd}/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
}

output "multi_tier_app.app.asg_key_file.name" {
  value = "${module.it_minimal_from_file.app.asg.name}"
}
