
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| db_pass | Password to use for DB | string | `mypass27` | no |
| name | a name/userid to use for namespacing the resources created in this exercise, e.g. jsmith | string | `<your name>` | no |
| vpc_id |  | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| app.asg.launch_configuration_name |  |
| app.asg.name |  |
| app.web.dns_name |  |
| db.web.address |  |
| db.web.endpoint |  |
| lb.web.dns_name |  |

