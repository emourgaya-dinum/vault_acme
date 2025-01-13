
mkdir -p /tmp/vault/data 
chmod -R 777 /tmp/vault/data
terraform init
terraform plan -var-file="variable.tfvars"
terraform apply -var-file="variable.tfvars"
