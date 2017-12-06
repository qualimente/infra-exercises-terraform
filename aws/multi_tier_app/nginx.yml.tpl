#cloud-config
# Cloud config for application servers

runcmd:
  - docker run -d -p 80:80 --name nginx nginx:1.13.7
