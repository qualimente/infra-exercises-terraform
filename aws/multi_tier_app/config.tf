// Configuring the AWS provider - START

variable "region" {
  description = "AWS region to use"
  default = "us-east-1"
}

provider "aws" {
  region = "${var.region}"
}

// Configuring the AWS provider - END


// Reconfigure backend to use remote state - START
terraform {
  backend "s3" {
    bucket     = "qm-training-cm-us-east-1"
    key        = "infra/terraform/qm-sandbox/us-east-1/cm/exercise-<your name>.tfstate"
    region     = "us-east-1"
    encrypt    = true
    dynamodb_table = "TerraformStateLock"
  }
}

// Reconfigure backend to use remote state - END