

resource "aws_iam_role" "codepipeline" {
  name = "codepipeline-role-${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# resource "aws_iam_role_policy" "codebuild_policy" {
#   name = "codebuild_policy_s3_${var.name}-${var.environment}"
#   role = "${var.codebuild_role_arn}"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect":"Allow",
#       "Action": [
#         "s3:GetObject",
#         "s3:*",
#         "s3:GetObjectVersion",
#         "s3:GetBucketVersioning"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.cp_bucket.arn}",
#         "${aws_s3_bucket.cp_bucket.arn}/*"
#       ]
#     },
#     {
#       "Effect":"Allow",
#       "Action": ["ecr:*"],
#       "Resource": ["*"]
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy_${var.name}-${var.environment}"
  role = "${aws_iam_role.codepipeline.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:*",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.cp_bucket.arn}",
        "${aws_s3_bucket.cp_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment_ECR" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess"
  role      = "${aws_iam_role.codepipeline.id}"
}


# resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
#   policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
#   role      = "${aws_iam_role.codebuild_role.id}"
# }