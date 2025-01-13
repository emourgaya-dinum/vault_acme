variable "vault_addr" {
  type        = string        
  description = " address de  vault"
  default     = "http://127.0.0.1:8200"
}

variable "unseal_keys" {
  type        = list(string)
  description = "List of unseal_key"
  default     = [""]
}

variable "pki_mount_path" {
  type        = string        
  description = " name of the  mount path"
  default     = "pki_local"
}

variable "ca_pem_path" {
  type  = string
  description = "Ca  pem Root path"
  default = ""
}

variable "ca_key_path" {
  type  = string
  description = "Ca  pem Root path"
  default = ""
}

variable "allowed_domain"{
  type = string
  description = "nom de  domain a signer"
}