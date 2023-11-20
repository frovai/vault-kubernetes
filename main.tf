terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "dynamodb_table" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//dynamodb"

  name                           = var.name
  hash_key                       = var.hash_key
  range_key                      = var.range_key
  point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
  attributes                     = var.attributes
  tags                           = var.tags_dynamo
}

module "kms" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//kms"

  alias                   = var.alias
  tags                    = var.tags_kms
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
}

module "kms_alias" {
  source        = "git::https://github.com/MYORGANIZATION/terraform-modules.git//kms-alias"
  alias         = var.alias
  target_key_id = module.kms.kms_key_id
}

module "iam_user" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//iam-user"

  user_name               = var.user_name
  password_reset_required = var.password_reset_required
}

module "iam_policy" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//iam-user-policy"

  name        = var.policy_name
  description = var.policy_description
  policy      = data.aws_iam_policy_document.policy.json
}

module "iam_user_policy_attachment" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//iam-user-policy-attachment"

  policy_attachment_name = var.policy_attachment_name
  policy_arn             = module.iam_policy.policy_arn
  users                  = [module.iam_user.iam_user_name]
}

module "iam_access_key" {
  source = "git::https://github.com/MYORGANIZATION/terraform-modules.git//iam-access-key"

  user = module.iam_user.iam_user_name
  ## Chave gerada ficará no SSM ( Parameter Store ) da AWS
  pgp_key = data.local_file.pgp_key.content_base64
}

data "local_file" "pgp_key" {
  filename = "/home/felipe/Desktop/Git-repos/vault-kubernetes/templates/public-key-binary.gpg"
}
