terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# Cloud Shell auto-authenticates via the console session token — no API
# key/config needed when this is run inside OCI Cloud Shell.
provider "oci" {
  region = var.region
}
