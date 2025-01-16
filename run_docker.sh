
mkdir -p /tmp/vault/data 
chmod -R 777 /tmp/vault/data
#Unseal Key: 8wDsEGGMbZIjX/bA2BrutUDiK6Ftv8n2RlCH8aHG50Q=
#Root Token: root
export OPENBAO_DEV_LISTEN_ADDRESS=0.0.0.0:8200
export OPENBAO_DEV_ROOT_TOKEN_ID="root"

terraform plan -var-file="variable.tfvars"
terraform apply -var-file="variable.tfvars"