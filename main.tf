data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}
#==============================================================================================================
# IAM ROLE - KUBERNETES CERT MANAGER
#==============================================================================================================
locals {
  eks_oidc_issuer = trimprefix(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://")
}

data "aws_iam_policy_document" "kubernetes_cert_manager_assume" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.eks_oidc_issuer}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "kubernetes_cert_manager" {
  count = var.enabled ? 1 : 0
  statement {
    actions = [
      "route53:GetChange"
    ]
    resources = [
      "arn:aws:route53:::change/*"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "route53:ListHostedZonesByName"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "kubernetes_cert_manager" {
  depends_on  = [var.mod_dependency]
  count       = var.enabled ? 1 : 0
  name        = "${var.cluster_name}-cert-manager"
  path        = "/"
  description = "Policy for cert-manager service"

  policy = data.aws_iam_policy_document.kubernetes_cert_manager[0].json
}

resource "aws_iam_role" "kubernetes_cert_manager" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_cert_manager_assume[0].json
}

resource "aws_iam_role_policy_attachment" "kubernetes_cert_manager" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.kubernetes_cert_manager[0].name
  policy_arn = aws_iam_policy.kubernetes_cert_manager[0].arn
}
#==============================================================================================================
# KUBERNETES RESOURCES - NAMESPACE
#==============================================================================================================
resource "kubernetes_namespace" "cert_manager" {
  depends_on = [var.mod_dependency]
  count      = (var.enabled && var.create_namespace && var.namespace != "kube-system") ? 1 : 0

  metadata {
    name = var.namespace
  }
}
#==============================================================================================================
# HELM CHART - CERT MANAGER
#==============================================================================================================
locals {
  default_set_values = {
    "serviceAccount.create"                                     = true
    "securityContext.fsGroup.enabled"                           = true
    "installCRDs"                                               = var.install_crd
    "serviceAccount.name"                                       = var.service_account_name
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.kubernetes_cert_manager[0].arn
    "securityContext.fsGroup"                                   = 1001
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [var.mod_dependency, kubernetes_namespace.cert_manager]
  count      = var.enabled ? 1 : 0
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.cert_manager[0].id : null

  dynamic "set" {
    for_each = try({ for key, value in local.default_set_values : key => value }, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set" {
    for_each = try({ for key, value in var.set_values.values : key => value }, {})
    content {
      name  = set.key
      value = set.value
    }
  }
}
#==============================================================================================================
# KUBECTL MANIFEST - CERTIFICATE ISSUER
#==============================================================================================================
resource "kubectl_manifest" "certificate" {
  count      = var.enabled ? length(var.certificates) : 0
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${var.certificates[count.index].name}
  namespace: ${var.certificates[count.index].namespace}
spec:
  secretName: ${var.certificates[count.index].secret_name}
  issuerRef:
    name: ${var.certificates[count.index].issuer_ref}
    kind: ${var.certificates[count.index].kind}
  dnsNames:
  - "${var.certificates[count.index].dns_name}"
YAML
  depends_on = [helm_release.cert_manager]
}

#==============================================================================================================
# KUBECTL MANIFEST - DNS 01
#==============================================================================================================
resource "kubectl_manifest" "dns01" {
  count      = var.enabled ? length(var.dns01) : 0
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ${var.dns01[count.index].kind}
metadata:
  name: ${var.dns01[count.index].name}
  namespace: ${var.dns01[count.index].namespace}
spec:
  acme:
    server: ${var.dns01[count.index].acme_server}
    email: ${var.dns01[count.index].acme_email}
    privateKeySecretRef:
      name: ${var.dns01[count.index].secret_key_ref}
    solvers:
    - selector:
        dnsZones:
          - "${var.dns01[count.index].dns_zone}"
      dns01:
        route53:
          region: ${var.dns01[count.index].region}
YAML
  depends_on = [helm_release.cert_manager]
}

#==============================================================================================================
# KUBECTL MANIFEST - HTTP 01
#==============================================================================================================
resource "kubectl_manifest" "http01" {
  count      = var.enabled ? length(var.http01) : 0
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ${var.http01[count.index].kind}
metadata:
  name: ${var.http01[count.index].name}
spec:
  acme:
    server: ${var.http01[count.index].acme_server}
    email: ${var.http01[count.index].acme_email}
    privateKeySecretRef:
      name: ${var.http01[count.index].secret_key_ref}
    solvers:
    - http01:
       ingress:
         class: ${var.http01[count.index].ingress_class}
YAML
  depends_on = [helm_release.cert_manager]
}
