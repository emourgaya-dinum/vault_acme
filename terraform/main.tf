provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}

# Effectuer l'unseal de Vault
resource "null_resource" "vault_unseal" {
  provisioner "local-exec" {
    command = <<EOT
    curl --request POST --data '{"key": "${var.unseal_keys[0]}"}' "${var.vault_addr}/v1/sys/unseal"
    EOT
  }
}

# # Configuration du backend PKI pour l'autorité intermédiaire
resource "vault_mount" "pki_intermediate" {
    depends_on = [ null_resource.vault_unseal ]
  path        = var.pki_mount_path
  type        = "pki"
  description = "Intermediate Certificate Authority"
  max_lease_ttl_seconds = 31536000 # 1 year
}

# generate csr to sign 
resource "vault_pki_secret_backend_intermediate_cert_request" "csr" {
  backend     = vault_mount.pki_intermediate.path
  type        = "exported" 
  common_name = " vaultIntermediate ${var.pki_mount_path} CA"
}

resource "local_file" "intermediate_csr" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.csr]
  filename   = "${path.module}/vault_pki.csr"
  content = vault_pki_secret_backend_intermediate_cert_request.csr.csr
}

resource "local_file" "openssl_config" {
  filename = "${path.module}/openssl.cnf"
  content  = <<-EOT
    [req]
    distinguished_name = req_distinguished_name
    prompt = no
    
    [req_distinguished_name]
    CN = Vault Intermediate ${var.pki_mount_path} CA
    
    [ v3_ca ]
    basicConstraints = critical,CA:TRUE
    keyUsage = critical,keyCertSign,cRLSign,digitalSignature
    extendedKeyUsage = serverAuth,clientAuth
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    EOT
}

resource "null_resource" "sign_certificate" {
  depends_on = [local_file.intermediate_csr, local_file.openssl_config]
  
  provisioner "local-exec" {
    command = <<-EOT
      openssl x509 -req \
        -in "${local_file.intermediate_csr.filename}" \
        -CA "${var.ca_pem_path}" \
        -CAkey "${var.ca_key_path}" \
        -CAcreateserial \
        -out "${path.module}/intermediate.pem" \
        -days 365 \
        -sha256 \
        -extfile "${local_file.openssl_config.filename}" \
        -extensions v3_ca
    EOT
  }
  triggers = {
    csr_content = local_file.intermediate_csr.content
  }
}

data "local_file" "signed_certificate" {
  depends_on = [null_resource.sign_certificate]
  filename   = "${path.module}/intermediate.pem"
}

# Import du certificat signé dans Vault
resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  depends_on  = [null_resource.sign_certificate]
  backend     = vault_mount.pki_intermediate.path
  certificate = data.local_file.signed_certificate.content
}



resource "vault_pki_secret_backend_config_urls" "distrib" {
  backend = vault_mount.pki_intermediate.path
  issuing_certificates    = ["${var.vault_addr}/v1/${var.pki_mount_path}/ca"]
  crl_distribution_points = ["${var.vault_addr}/v1/${var.pki_mount_path}/crl"]
}


# # # Créer un rôle pour émettre des certificats
resource "vault_pki_secret_backend_role" "pki_role" {
  backend             = vault_mount.pki_intermediate.path
  name                = "pki_role"
  allowed_domains     = ["${var.allowed_domain}"]
  allow_subdomains    = true
  max_ttl             = "720h"
}


resource "vault_generic_endpoint" "cluster_config" {
  depends_on           = [vault_pki_secret_backend_intermediate_set_signed.intermediate]
  path                 = "${var.pki_mount_path}/config/cluster"
  disable_delete       = true
  ignore_absent_fields = true
  
  data_json = jsonencode({
    path     = "${var.vault_addr}/v1/${var.pki_mount_path}"
    aia_path = "${var.vault_addr}/v1/${var.pki_mount_path}"
  })
}

resource "vault_generic_endpoint" "acme_headers" {
  depends_on           = [vault_generic_endpoint.cluster_config]
  path                 = "sys/mounts/${var.pki_mount_path}/tune"
  disable_delete       = true
  ignore_absent_fields = true
  
  data_json = jsonencode({
    passthrough_request_headers = ["If-Modified-Since"],
    allowed_response_headers = [
      "Last-Modified",
      "Location",
      "Replay-Nonce",
      "Link"
    ]
  })
}

resource "vault_generic_endpoint" "enable_acme" {
  depends_on           = [vault_generic_endpoint.acme_headers]
  path                 = "${var.pki_mount_path}/config/acme"
  disable_delete       = true
  ignore_absent_fields = true
  
  data_json = jsonencode({
    enabled = true,
    allowed_roles = ["*"]
  })
}


