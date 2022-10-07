# Kong-api-gateway
This repo contains :
- Kong-api-gateway + konga IAC and vm provisioning
- Kong plugin for google cloud function auth

# How to install

## Docker image
To setup the kong api-gateway with the google cloud function plugin, you need to have  the docker image pushed into your favourite registry
I have pushed an image called benmstm/kong-cf:2.7.1 (containing the plugin integration)

## Terraform
All you have to do then is to launch the CI to install the api-gateway

## Ansible
The ansible is used in the first run to init components like databse schema, seeding kong ...