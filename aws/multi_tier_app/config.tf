// Configuring the AWS provider - START

variable "region" {
  description = "AWS region to use"
  default     = "us-west-2"
}

//provider "aws" {
//  region = "${var.region}"
//}


// Configuring the AWS provider - END


// Reconfigure backend to use remote state - START


//terraform {
//  backend "s3" {
//    bucket     = "qm-training-cm-us-west-2"
//    key        = "infra/terraform/qm-training/us-west-2/cm/exercise-<your name>.tfstate"
//    region     = "us-west-2"
//    encrypt    = true
//    dynamodb_table = "TerraformStateLock"
//  }
//}


// Reconfigure backend to use remote state - END

