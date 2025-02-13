terraform destroy -var-file="variable.tfvars"
rm -f openssl.cnf
rm -f vault_pki.csr
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
