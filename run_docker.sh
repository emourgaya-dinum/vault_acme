
mkdir -p /tmp/vault/data 
chmod -R 777 /tmp/vault/data
#Unseal Key: 8wDsEGGMbZIjX/bA2BrutUDiK6Ftv8n2RlCH8aHG50Q=
#Root Token: root
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="root"

terraform plan -var-file="variable.tfvars"
terraform apply -var-file="variable.tfvars"