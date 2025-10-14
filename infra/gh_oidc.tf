data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "gh_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { type = "Federated", identifiers = [data.aws_iam_openid_connect_provider.github.arn] }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gh_deploy" {
  name               = "gh-actions-static-site-deploy"
  assume_role_policy = data.aws_iam_policy_document.gh_assume.json
}

data "aws_iam_policy_document" "deploy_policy" {
  statement {
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${module.site.bucket_name}",
      "arn:aws:s3:::${module.site.bucket_name}/*"
    ]
  }
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy_policy" {
  name   = "static-site-deploy-policy"
  policy = data.aws_iam_policy_document.deploy_policy.json
}

resource "aws_iam_role_policy_attachment" "deploy_attach" {
  role       = aws_iam_role.gh_deploy.name
  policy_arn = aws_iam_policy.deploy_policy.arn
}

