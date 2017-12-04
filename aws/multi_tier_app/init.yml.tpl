#cloud-config
# Cloud config for application servers

runcmd:
  - docker run -d -p 80:80 -e POSTGRES_ENDPOINT='${postgres_endpoint}' nginx:1.13.7
  