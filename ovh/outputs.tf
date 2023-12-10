# Openstack
output "openstackID" {
  value = one(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)
}
#Network
output "gateway_ip1" {
  value     = ovh_cloud_project_network_private_subnet.subnet1.gateway_ip
  sensitive = false
}
# output "gateway_ip2" {
#   value     = ovh_cloud_project_network_private_subnet.subnet2.gateway_ip
#   sensitive = false
# }

#Kubernetes
output "kubeconfig_file" {
  value     = ovh_cloud_project_kube.mycluster.kubeconfig
  sensitive = true
}
output "mycluster-host" {
  value     = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].host
  sensitive = true
}

# output "mycluster-cluster-ca-certificate" {
#   value     = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].cluster_ca_certificate
#   sensitive = true
# }

# output "mycluster-client-certificate" {
#   value     = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_certificate
#   sensitive = true
# }

# output "mycluster-client-key" {
#   value     = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_key
#   sensitive = true
# }

# Opensearch
# output "opensearch_admin_password" {
#   value     = ovh_cloud_project_database_opensearch_user.admin.password
#   sensitive = true
# }

# output "opensearch_user_password" {
#   value     = ovh_cloud_project_database_opensearch_user.user.password
#   sensitive = true
# }


# Deployments 
output "kubernetes_dashboard_service_metadata" {
  value = helm_release.kubernetes_dashboard.metadata
}
output "kubernetes_dashboard_url" {
  value = "http://localhost:9080"
}
