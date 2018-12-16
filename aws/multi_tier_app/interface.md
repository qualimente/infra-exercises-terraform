
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| availability_zones | List of availability zones to use | list | `<list>` | no |
| db_pass | Password to use for DB | string | `mypass27` | no |
| name | a name/userid to use for namespacing the resources created in this exercise, e.g. jsmith | string | `<your name>` | no |
| vpc_id |  | string | `vpc-58a29221` | no |

## Outputs

| Name | Description |
|------|-------------|
| app.web.dns_name |  |
| asg_launch_configuration_name |  |
| asg_name |  |
| db.web.address |  |
| db.web.endpoint |  |
| lb.web.dns_name |  |

