// Instantiate a minimal version of the module for testing
provider "aws" {
  //alias  = "testing"
  region = "us-east-1"
}

resource "random_id" "testing_suffix" {
  byte_length = 4
}

locals {
  name = "${var.name}${random_id.testing_suffix.hex}"
}

module "it_minimal" {
  //instantiate multi_tier_app module for a minimal integration test
  source = "../../../"

  name = "${local.name}"
  vpc_id = "vpc-58a29221"

//  providers = {
//    aws = "aws.testing"
//  }

}

variable "name" {
  type = "string"
}


output "testing_suffix_hex" {
  value = "${random_id.testing_suffix.hex}"
}

output "multi_tier_app.lb.web.dns_name" {
  value = "${module.it_minimal.lb.web.dns_name}"
}

output "multi_tier_app.app.web.dns_name" {
  value = "${module.it_minimal.app.web.dns_name}"
}

output "terraform_state" {
  description = "The path to the Terraform state file; used in the state_file control"
  value       = "${path.cwd}/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
}
