#==============================================================================================================
# HELM CHART - CERT MANAGER
#==============================================================================================================
output "helm_release_name" {
  description = "helm release name"
  value       = helm_release.cert_manager[0].name
}

output "helm_release_namespace" {
  description = "helm release namespace"
  value       = helm_release.cert_manager[0].namespace
}
