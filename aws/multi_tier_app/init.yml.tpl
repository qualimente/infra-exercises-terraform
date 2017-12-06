#cloud-config
# Cloud config for application servers

runcmd:
  - docker run -d -p 80:8080 -e POSTGRES_HOST='${postgres_address}' -e POSTGRES_PORT='5432' -e POSTGRES_USER='exercise' -e POSTGRES_PASSWORD='mypass27' -e POSTGRES_DB='exercise' -e POSTGRES_SSLMODE='disable' qualimente/exerciseapi
  - docker run -d -p 8080:80 -e POSTGRES_ENDPOINT='${postgres_endpoint}' nginx:1.13.7
