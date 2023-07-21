# terraform-aws-eks-cert-manager

Terraform module for deploying Kubernetes [cert-manager](https://cert-manager.io/docs/), cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self signed.

## Usage

```bash
module "cert_manager" {
  source = "easy-modules/cert-manager/easy"
  enabled            = true
  cluster_name       = "eks-cluster"

  dns01 = [
    {
      name           = "letsencrypt-staging"
      namespace      = "default"
      kind           = "ClusterIssuer"
      dns_zone       = "example.com"
      region         = "us-east-1" # data.aws_region.current.name
      secret_key_ref = "letsencrypt-staging"
      acme_server    = "https://acme-staging-v02.api.letsencrypt.org/directory"
      acme_email     = "your@email.com"
    },
    {
      name           = "letsencrypt-prod"
      namespace      = "default"
      kind           = "ClusterIssuer"
      dns_zone       = "example.com"
      region         = "us-east-1" # data.aws_region.current.name
      secret_key_ref = "letsencrypt-prod"
      acme_server    = "https://acme-v02.api.letsencrypt.org/directory"
      acme_email     = "your@email.com"
    }
  ]

  # In case you want to use HTTP01 challenge method uncomment this section
  # and comment dns01 variable
  # http01 = [
  #   {
  #     name           = "letsencrypt-staging"
  #     kind           = "ClusterIssuer"
  #     ingress_class  = "nginx"
  #     secret_key_ref = "letsencrypt-staging"
  #     acme_server    = "https://acme-staging-v02.api.letsencrypt.org/directory"
  #     acme_email     = "your@email.com"
  #   },
  #   {
  #     name           = "letsencrypt-prod"
  #     kind           = "ClusterIssuer"
  #     ingress_class  = "nginx"
  #     secret_key_ref = "letsencrypt-prod"
  #     acme_server    = "https://acme-v02.api.letsencrypt.org/directory"
  #     acme_email     = "your@email.com"
  #   }
  # ]

  # In case you want to create certificates uncomment this block
  # certificates = [
  #   {
  #     name           = "example-com"
  #     namespace      = "default"
  #     kind           = "ClusterIssuer"
  #     secret_name    = "example-com-tls"
  #     issuer_ref     = "letsencrypt-prod"
  #     dns_name       = "*.example.com"
  #   }
  # ]
}
```

#### ingress.yaml

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod # This should match the ClusterIssuer created
    # cert-manager.io/issuer: letsencrypt-prod # In case you choose Issuer instead of ClusterIssuer
  labels:
    app: app
spec:
  rules:
  - host: app.example.com
    http:
      paths:
        - path: /*
          backend:
            serviceName: service
            servicePort: 80
  tls:
    - hosts:
        # - "*.example.com" # Example of wildcard
        - app.example.com
      secretName: app-example-com-prod-tls
```

#### Detached Wildcard Certificate
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - '*.example.com'
```

#### Decoding the Secret
You can check for any existing resources with the following command:
```bash
kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces
```

To view the contents of the Secret we just created, you can run the following command:
```bash
kubectl get secret example-com-tls -o jsonpath='{.data}'
```

Now you can decode the `tls.key` or `tls.crt` data:
```bash
echo 'MWYyZDFlMmU2N2Rm' | base64 -d
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0, < 5.9 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 1.0, < 2.10.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 1.10.0, < 2.22.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0, < 5.9 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 1.0, < 2.10.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 1.10.0, < 2.22.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.kubernetes_cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.kubernetes_cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.kubernetes_cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.certificate](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.dns01](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.http01](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.cert_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.kubernetes_cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kubernetes_cert_manager_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | List of certificates to be created | <pre>list(object({<br>    name        = string<br>    namespace   = string<br>    secret_name = string<br>    issuer_ref  = string<br>    kind        = string<br>    dns_name    = string<br>  }))</pre> | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create Kubernetes namespace with name defined by `namespace`. | `bool` | `true` | no |
| <a name="input_dns01"></a> [dns01](#input\_dns01) | List of DNS01 to be created | <pre>list(object({<br>    name           = string<br>    namespace      = string<br>    kind           = string<br>    dns_zone       = string<br>    region         = string<br>    secret_key_ref = string<br>    acme_server    = string<br>    acme_email     = string<br>  }))</pre> | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Variable indicating whether deployment is enabled. | `bool` | `true` | no |
| <a name="input_helm_chart_name"></a> [helm\_chart\_name](#input\_helm\_chart\_name) | Cert Manager Helm chart name to be installed | `string` | `"cert-manager"` | no |
| <a name="input_helm_chart_release_name"></a> [helm\_chart\_release\_name](#input\_helm\_chart\_release\_name) | Helm release name | `string` | `"cert-manager"` | no |
| <a name="input_helm_chart_repo"></a> [helm\_chart\_repo](#input\_helm\_chart\_repo) | Cert Manager repository name. | `string` | `"https://charts.jetstack.io"` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Cert Manager Helm chart version. | `string` | `"1.1.0"` | no |
| <a name="input_http01"></a> [http01](#input\_http01) | List of HTTP01 to be created | <pre>list(object({<br>    name           = string<br>    kind           = string<br>    ingress_class  = string<br>    secret_key_ref = string<br>    acme_server    = string<br>    acme_email     = string<br>  }))</pre> | `[]` | no |
| <a name="input_install_crd"></a> [install\_crd](#input\_install\_crd) | To automatically install and manage the CRDs as part of your Helm release. | `bool` | `true` | no |
| <a name="input_mod_dependency"></a> [mod\_dependency](#input\_mod\_dependency) | Dependence variable binds all AWS resources allocated by this module, dependent modules reference this variable. | `any` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace to deploy Cert Manager Helm chart. | `string` | `"cert-manager"` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | External Secrets service account name | `string` | `"cert-manager"` | no |
| <a name="input_set_values"></a> [set\_values](#input\_set\_values) | External Secrets values | `map(any)` | <pre>{<br>  "values": {}<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | helm release name |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | helm release namespace |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
