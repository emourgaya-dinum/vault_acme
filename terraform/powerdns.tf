terraform {
  required_providers {
    powerdns = {
      source  = "pan-net/powerdns"
    }
  }
}

provider "powerdns" {
  server_url    = var.powerdns_addr
  api_key    = var.powerdns_api_key                      
}

resource "powerdns_zone" "example_zone" {
  name        = "example.com." 
  kind        = "Master"
  nameservers = ["ns.example.com."]
}