#cloud-config
# Cloud config for application servers

runcmd:
  - docker run -d -p 80:8080 --name exerciseapi -e POSTGRES_HOST='${postgres_address}' -e POSTGRES_PORT='5432' -e POSTGRES_USER='exercise' -e POSTGRES_PASSWORD='${postgres_password}' -e POSTGRES_DB='exercise' -e POSTGRES_SSLMODE='disable' qualimente/exerciseapi
