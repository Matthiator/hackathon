terraform {
  required_version = "v1.1.4"
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "1.29.0"
    }
  }
}

locals {
  bucket_name = "${var.region}-${var.context}-${var.stage}-tfstate"
}

provider "opentelekomcloud" {
  auth_url    = "https://iam.${var.region}.otc.t-systems.com/v3"
  tenant_name = var.region
}

resource "opentelekomcloud_obs_bucket" "tf_remote_state" {
  bucket     = local.bucket_name
  acl        = "private"
  versioning = true
  server_side_encryption {
    algorithm  = "kms"
    kms_key_id = opentelekomcloud_kms_key_v1.tf_remote_state_bucket_kms_key.id
  }
}

resource "random_id" "id" {
  byte_length = 4
}

resource "opentelekomcloud_kms_key_v1" "tf_remote_state_bucket_kms_key" {
  key_alias       = "${local.bucket_name}-key-${random_id.id.hex}"
  key_description = "${local.bucket_name} encryption key"
  pending_days    = 7
  is_enabled      = "true"
}

output "backend_config" {
  value = <<EOT
    Put this under ${var.context}/${var.stage}/settings.tf under TODO

    backend "s3" {
      bucket = "${opentelekomcloud_obs_bucket.tf_remote_state.bucket}"
      kms_key_id = "arn:aws:kms:eu-nl:${opentelekomcloud_kms_key_v1.tf_remote_state_bucket_kms_key.domain_id}:key/${opentelekomcloud_kms_key_v1.tf_remote_state_bucket_kms_key.id}"
      key = "tfstate"
      region = "${opentelekomcloud_obs_bucket.tf_remote_state.region}"
      endpoint = "obs.eu-nl.otc.t-systems.com"
      encrypt = true
      skip_region_validation = true
      skip_credentials_validation = true
    }

    Put this under ${var.context}/${var.stage}/kubernetes/settings.tf under TODO

    backend "s3" {
      bucket = "${opentelekomcloud_obs_bucket.tf_remote_state.bucket}"
      kms_key_id = "arn:aws:kms:eu-nl:${opentelekomcloud_kms_key_v1.tf_remote_state_bucket_kms_key.domain_id}:key/${opentelekomcloud_kms_key_v1.tf_remote_state_bucket_kms_key.id}"
      key = "tfstate-kubernetes"
      region = "${opentelekomcloud_obs_bucket.tf_remote_state.region}"
      endpoint = "obs.eu-nl.otc.t-systems.com"
      encrypt = true
      skip_region_validation = true
      skip_credentials_validation = true
    }
  EOT
}
