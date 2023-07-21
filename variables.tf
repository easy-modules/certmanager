variable "enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled."
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "service_account_name" {
  type        = string
  default     = "cert-manager"
  description = "External Secrets service account name"
}

#==============================================================================================================
# HELM CHART - CERT MANAGER
#==============================================================================================================
variable "helm_chart_name" {
  type        = string
  default     = "cert-manager"
  description = "Cert Manager Helm chart name to be installed"
}

variable "helm_chart_release_name" {
  type        = string
  default     = "cert-manager"
  description = "Helm release name"
}

variable "helm_chart_version" {
  type        = string
  default     = "1.1.0"
  description = "Cert Manager Helm chart version."
}

variable "helm_chart_repo" {
  type        = string
  default     = "https://charts.jetstack.io"
  description = "Cert Manager repository name."
}

variable "install_crd" {
  type        = bool
  default     = true
  description = "To automatically install and manage the CRDs as part of your Helm release."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether to create Kubernetes namespace with name defined by `namespace`."
}

variable "namespace" {
  type        = string
  default     = "cert-manager"
  description = "Kubernetes namespace to deploy Cert Manager Helm chart."
}

variable "mod_dependency" {
  type        = any
  default     = null
  description = "Dependence variable binds all AWS resources allocated by this module, dependent modules reference this variable."
}

variable "set_values" {
  type        = map(any)
  description = "External Secrets values"
  default = {
    values = {}
  }
}

#================================================================================
# CERTIFICATE
#================================================================================
variable "certificates" {
  type = list(object({
    name        = string
    namespace   = string
    secret_name = string
    issuer_ref  = string
    kind        = string
    dns_name    = string
  }))
  default     = []
  description = "List of certificates to be created"
}
#================================================================================
# DNS 01
#================================================================================
variable "dns01" {
  type = list(object({
    name           = string
    namespace      = string
    kind           = string
    dns_zone       = string
    region         = string
    secret_key_ref = string
    acme_server    = string
    acme_email     = string
  }))
  default     = []
  description = "List of DNS01 to be created"
}
#================================================================================
# HTTP 01
#================================================================================
variable "http01" {
  type = list(object({
    name           = string
    kind           = string
    ingress_class  = string
    secret_key_ref = string
    acme_server    = string
    acme_email     = string
  }))
  default     = []
  description = "List of HTTP01 to be created"
}
