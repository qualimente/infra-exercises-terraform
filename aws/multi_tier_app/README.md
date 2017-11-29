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

