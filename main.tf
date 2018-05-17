### For looking up info from the other Terraform States
variable "name" {
  description = "The project name"
}

# variable "app_name"           { 
#   default = ""
#   description = "The project name" 
# }

### Local Variables

#Github Variables
variable "gh_owner" {}

variable "gh_repo" {}
variable "gh_branch" {}
variable "gh_token" {}

variable "environment" {
  default = "staging"
}

variable "cluster_name" {}
variable "service_name" {}
variable "family_name" {}
variable "codebuild_project_name" {}
variable "codebuild_role_arn" {}

variable "namespace" {
  default = "global"
}

variable "stage" {
  default = "default"
}

module "pipeline_label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.5"

  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "pipeline"
  tags      = "${merge(map("ManagedBy", "Terraform"), var.tags)}"
}

# locals {
#   b_name = "cp-${var.name}-${var.environment}"
#   b_name_hyphen = "${substr(join("-", split("_", lower(local.b_name))), 0, 20)}"
# }
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "${module.pipeline_label.id}"
  acl           = "private"
  force_destroy = true
}

output "bucket_id" {
  value = "${aws_s3_bucket.codepipeline_bucket.bucket}"
}

# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }

resource "aws_codepipeline" "pipeline" {
  name     = "${module.pipeline_label.id}"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  tags = "${module.pipeline_label.tags}"

  artifact_store {
    location = "${aws_s3_bucket.cp_bucket.bucket}"
    type     = "S3"

    # encryption_key {
    #   id   = "${data.aws_kms_alias.s3kmskey.arn}"
    #   type = "KMS"
    # }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["app_artifacts"]

      configuration {
        OAuthToken           = "${var.gh_token}"
        Owner                = "${var.gh_owner}"
        Repo                 = "${var.gh_repo}"
        Branch               = "${var.gh_branch}"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["app_artifacts"]
      output_artifacts = ["task_artifacts"]
      version          = "1"

      configuration {
        ProjectName = "${var.codebuild_project_name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      version         = "1"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["task_artifacts"]

      configuration {
        ClusterName = "${var.cluster_name}"
        ServiceName = "${var.service_name}"

        # FileName    = "task_definition.json"
      }
    }
  }
}

data "aws_caller_identity" "default" {}

data "aws_region" "default" {}
