variable "region" {
  description = "OCI region (home region; permanent once the account is created)"
  type        = string
  default     = "us-phoenix-1"
}

variable "compartment_ocid" {
  description = "Compartment to create resources in (root/tenancy compartment is fine for a personal Always Free setup)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key contents for instance access. Generate with: ssh-keygen -t ed25519 -f ~/.ssh/openclaw_vm -N \"\""
  type        = string
}

variable "instance_ocpus" {
  description = "OCPUs for the Ampere A1 Flex instance. Always Free covers up to 2 total as of the June 2026 tier change."
  type        = number
  default     = 2
}

variable "instance_memory_gbs" {
  description = "Memory (GB) for the Ampere A1 Flex instance. Always Free covers up to 12 total."
  type        = number
  default     = 12
}

variable "boot_volume_size_gbs" {
  type    = number
  default = 50
}

variable "availability_domain_index" {
  description = "0-based index into this region's availability domains. If apply fails with 'Out of host capacity', try bumping this (0, 1, 2) and re-applying."
  type        = number
  default     = 0
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach SSH (22). Defaults open; narrow to your own IP for tighter security if you want."
  type        = string
  default     = "0.0.0.0/0"
}
