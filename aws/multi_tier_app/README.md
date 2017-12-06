# Multi-Tier App on AWS #

This exercise will challenge you to create a 'basic' multi-tier application on AWS.

The application will be a webapp that uses a Cloud-managed Postgres instance, but will also require the provisioning of attendant networking and security infrastructure.

In total, the exercise will step through provisioning:

* using existing VPC and subnet network resources
* load balancer
* application instances
* an RDS Postgres database instance
* network and security groups configuration that permits:

    * ingress of http(s) traffic to the load balancer from the Internet
    * http(s) traffic from the lb to the app instances
    * ssh access to the app instances from the Internet
    * access from the application instances to the database

* credential management
    * a key pair for use with app instances
    * master and IAM credential information for the database instance

# Exercise #

## Getting Started: Configuring the AWS provider ##

Create a config.tf with an AWS provider specified to use us-east-1

Export environment variables for:

`AWSAWS_DEFAULT_REGION=us-east-1`
`AWS_ACCESS_KEY_ID=<your api access key>`
`AWS_SECRET_ACCESS_KEY=<your secret access key>`

Create an empty main.tf file.

Run:

`terraform init`
`terraform plan`

Expected Result: 
Terraform should initialize plugins and report zero resource additions, modifications, and deletions

## Resolve existing network resources ##

Use [aws_subnet_ids](https://www.terraform.io/docs/providers/aws/d/subnet_ids.html) data provider to resolve the subnet ids in the region's default VPC.

Hint: default VPC id for region is available on the EC2 Dashboard, e.g. vpc-58a29221

## Create an EC2 instance ##

Create an AWS Key Pair using an ssh keypair.

Aside: how to generate an keypair `ssh-keygen -t rsa -f exercise.id_rsa` # do not specify a passphrase

Hint: Use the file function in Terraform [interpolation syntax](https://www.terraform.io/docs/configuration/interpolation.html)

Run `terraform plan`

Expected Result: `1 to add, 0 to change, 0 to destroy.` 

Run `terraform apply`

Create one t2.medium EC2 instance using [Amazon ECS Optimized Linux](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html)
ami details:

* ami id in us-east-1: ami-fad25980
* name: amzn-ami-2017.09.d-amazon-ecs-optimized 

The EC2 instance should:

* reference and use the generated keypair
* be launched into one of the default vpc subnets
* have a public IP
* a tag of `Name=exercise-<yourname>`

Hint: `subnet_id = "${element(data.aws_subnet_ids.default_vpc.ids, 0)}"`

Digging Deeper:
Inspect Terraform state:
`head terraform.tfstate`

What format does this look like?

Find your the instance you just created and look at it in AWS EC2 console:
`grep i-.* terraform.tfstate`

## Reconfigure backend to use remote state ##

Add to config.tf:

```
terraform {
  backend "s3" {
    bucket     = "qm-training-cm-us-east-1"
    key        = "infra/terraform/qm-sandbox/us-east-1/cm/exercise-<your name>.tfstate"
    region     = "us-east-1"
    encrypt    = true
    lock_table = "TerraformStateLock"
  }
}
```


## (Optional) Refactor to Support Multiple Instances ##

Consider that we might want to have multiple instances...

Add the 'count' field to the `aws_instance` resource definition, set to 1.  Reference `count.index` in subnet lookup.

## Create Firewall Rules to Permit Access ##

Create the following security groups:
 
1. public-web - a security group that permits http and https access from the public Internet (tcp ports 80 & 443) 
2. public-ssh - a security group that permits ssh access from the public Internet (tcp port 22)
3. internal-web - a security group that permits http access only from sources in the VPC (tcp port 80) 
4. outbound - a security group that permits access from the VPC to the Internet

hint:

## Attach Security Groups to EC2 Instance ##

Attach the public-ssh, internal-web, and outbound security groups to the ec2 instance.

You should now be able to login to the instance via ssh with:
`ssh -i ./exercise.id_rsa <public DNS>`

e.g.
```
ssh -i ./exercise.id_rsa ec2-user@ec2-107-23-217-33.compute-1.amazonaws.com

   __|  __|  __|
   _|  (   \__ \   Amazon ECS-Optimized Amazon Linux AMI 2017.09.d
 ____|\___|____/

For documentation visit, http://aws.amazon.com/documentation/ecs
```

# Run Webserver #

```
docker run -d -p 80:80 nginx:1.13.7
```

## Create an ELB ##

Create an Elastic Load Balancer.



Connect ELB to app instance.