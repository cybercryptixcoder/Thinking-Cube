resource "oci_core_vcn" "openclaw" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "openclaw-vcn"
  dns_label      = "openclawvcn"
}

resource "oci_core_internet_gateway" "openclaw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openclaw.id
  display_name   = "openclaw-igw"
  enabled        = true
}

resource "oci_core_route_table" "openclaw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openclaw.id
  display_name   = "openclaw-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.openclaw.id
  }
}

resource "oci_core_security_list" "openclaw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openclaw.id
  display_name   = "openclaw-seclist"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH only. OpenClaw connects out to WhatsApp/Telegram; nothing needs to
  # be reachable inbound besides SSH for administration.
  ingress_security_rules {
    source   = var.ssh_allowed_cidr
    protocol = "6" # TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "openclaw" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.openclaw.id
  cidr_block                 = "10.0.0.0/24"
  display_name               = "openclaw-subnet"
  dns_label                  = "openclawsub"
  route_table_id             = oci_core_route_table.openclaw.id
  security_list_ids          = [oci_core_security_list.openclaw.id]
  prohibit_public_ip_on_vnic = false
}
