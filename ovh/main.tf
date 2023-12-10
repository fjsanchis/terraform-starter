#### NETWORK
resource "ovh_vrack_cloudproject" "vpc" {
  service_name = var.ovh_vrack_id         # vrack ID
  project_id   = var.ovh_cloud_project_id # Public Cloud service name
}
resource "ovh_cloud_project_network_private" "network" {
  service_name = ovh_vrack_cloudproject.vpc.project_id
  vlan_id      = 0
  name         = "${local.naming_prefix}-vpc"
  regions      = ["${var.region}"]
  depends_on   = [ovh_vrack_cloudproject.vpc]
}
resource "ovh_cloud_project_network_private_subnet" "subnet1" {
  service_name = ovh_cloud_project_network_private.network.service_name
  network_id   = ovh_cloud_project_network_private.network.id
  
  # whatever region, for test purpose
  region     = var.region
  start      = "192.168.168.100"
  end        = "192.168.168.200"
  network    = "192.168.168.0/24"
  dhcp       = true
  no_gateway = false

  depends_on = [ovh_cloud_project_network_private.network]
}
# resource "ovh_cloud_project_network_private_subnet" "subnet2" {
#   service_name = ovh_cloud_project_network_private.network.service_name
#   network_id   = ovh_cloud_project_network_private.network.id

#   # whatever region, for test purpose
#   region     = var.region
#   start      = "192.168.169.100"
#   end        = "192.168.169.200"
#   network    = "192.168.169.0/24"
#   dhcp       = true
#   no_gateway = false

#   depends_on = [ovh_cloud_project_network_private.network]
# }

### OPENSEARCH
# resource "ovh_cloud_project_database" "opensearchdb" {
#   service_name            = var.ovh_cloud_project_id
#   description             = "${local.naming_prefix}-opensearch"
#   engine                  = "opensearch"
#   version                 = "2"
#   plan                    = "essential"
#   opensearch_acls_enabled = true
#   flavor                  = "db1-4"

#   nodes {
#     region     = "GRA"
#     network_id = ovh_cloud_project_network_private.network.id
#     subnet_id  = ovh_cloud_project_network_private_subnet.subnet1.id
#   }

# }
# resource "ovh_cloud_project_database_opensearch_pattern" "pattern" {
#   service_name    = var.ovh_cloud_project_id
#   cluster_id      = ovh_cloud_project_database.opensearchdb.id
#   max_index_count = 5
#   pattern         = "logs_*"
# }
# resource "ovh_cloud_project_database_opensearch_user" "admin" {
#   service_name = var.ovh_cloud_project_id
#   cluster_id   = ovh_cloud_project_database.opensearchdb.id
#   acls {
#     pattern    = "*"
#     permission = "admin"
#   }
#   name = "admin"
#   #password_reset  = "reset1"
# }
# resource "ovh_cloud_project_database_opensearch_user" "user" {
#   service_name = var.ovh_cloud_project_id
#   cluster_id   = ovh_cloud_project_database.opensearchdb.id
#   acls {
#     pattern    = "logs_*"
#     permission = "read"
#   }
#   acls {
#     pattern    = "logs_*"
#     permission = "write"
#   }
#   acls {
#     pattern    = "data_*"
#     permission = "deny"
#   }
#   name = "johndoe"
#   #password_reset  = "reset1"
# }

### KUBE CLUSTER
resource "ovh_cloud_project_kube" "mycluster" {
  service_name = var.ovh_cloud_project_id
  name         = "${local.naming_prefix}-kube-cluster"
  region       = var.region
  version      = var.kube_version

  private_network_id = tolist(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)[0]

  private_network_configuration {
    default_vrack_gateway              = ""
    private_network_routing_as_default = false
  }

  depends_on = [ovh_cloud_project_network_private.network]
}
resource "ovh_cloud_project_kube_nodepool" "pool" {
  service_name  = var.ovh_cloud_project_id
  kube_id       = ovh_cloud_project_kube.mycluster.id
  name          = "${local.naming_prefix}-pool"
  flavor_name   = var.instance_type
  anti_affinity = true
  autoscale     = true
  desired_nodes = 3
  max_nodes     = 3
  min_nodes     = 3

  template {
    metadata {
      annotations = {
        k1 = "v1"
        k2 = "v2"
      }
      finalizers = ["ovhcloud.com/v1beta1", "ovhcloud.com/v1"]
      labels = {
        k3 = "v3"
        k4 = "v4"
      }
    }
    spec {
      unschedulable = false
      taints = [
        {
          effect = "PreferNoSchedule"
          key    = "k"
          value  = "v"
        }
      ]
    }
  }
}

## Deployment Configuaration
provider "kubernetes" {
  host                   = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].host
  client_certificate     = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_certificate)
  client_key             = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_key)
  cluster_ca_certificate = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].host
    client_certificate     = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_certificate)
    client_key             = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].client_key)
    cluster_ca_certificate = base64decode(ovh_cloud_project_kube.mycluster.kubeconfig_attributes[0].cluster_ca_certificate)
  }
  # private registry
  # registry {
  #   url = "oci://private.registry"
  #   username = "username"
  #   password = "password"
  # }
  # # localhost registry with password protection
  # registry {
  #   url = "oci://localhost:5000"
  #   username = "username"
  #   password = "password"
  # }
}

## Deployment
resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}
resource "helm_release" "kubernetes_dashboard" {
  # Name of the release in the cluster
  name = "kubernetes-dashboard"

  # Name of the chart to install
  repository = "https://kubernetes.github.io/dashboard/"

  # Version of the chart to use
  chart = "kubernetes-dashboard"

  # Wait for the Kubernetes namespace to be created
  depends_on = [kubernetes_namespace.kubernetes_dashboard]

  # Set the namespace to install the release into
  namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name

  # Set service type to LoadBalancer
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  # Set service external port to 9080
  set {
    name  = "service.externalPort"
    value = "9080"
  }

  # Set protocol to HTTP (not HTTPS)
  set {
    name  = "protocolHttp"
    value = "true"
  }

  # Enable insecure login (no authentication)
  set {
    name  = "enableInsecureLogin"
    value = "true"
  }

  # Enable cluster read only role (no write access) for the dashboard user
  set {
    name  = "rbac.clusterReadOnlyRole"
    value = "true"
  }

  # Enable metrics scraper (required for the CPU and memory usage graphs)
  set {
    name  = "metricsScraper.enabled"
    value = "true"
  }

  # Wait for the release to be deployed
  wait = true
}

resource "kubernetes_namespace" "nginx-ingress" {
  depends_on = [ovh_cloud_project_kube.mycluster, ovh_cloud_project_kube_nodepool.pool]
  metadata {
    annotations = {
      name = "nginx-ingress"
    }

    labels = {
      mylabel = "nginx-ingress-namespace"
    }

    name = "nginx-ingress"
  }
}
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  namespace  = "nginx-ingress"
  set {
    name  = "service.type"
    value = "ClusterIP"
  }
}

resource "kubernetes_namespace" "argocd" {
  depends_on = [ovh_cloud_project_kube.mycluster, ovh_cloud_project_kube_nodepool.pool]
  metadata {
    annotations = {
      name = "argocd"
    }

    labels = {
      mylabel = "argocd-namespace"
    }

    name = "argocd"
  }
}
# Install argocd helm chart using terraform
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.35.0"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# resource "kubernetes_deployment" "example" {
#   depends_on = [kubernetes_namespace.argocd]
#   metadata {
#     name      = "terraform-example"
#     namespace = "argocd"
#     labels = {
#       test = "MyExampleApp"
#     }
#   }

#   spec {
#     replicas = 3

#     selector {
#       match_labels = {
#         test = "MyExampleApp"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           test = "MyExampleApp"
#         }
#       }

#       spec {
#         container {
#           image = "nginx:1.21.6"
#           name  = "example"

#           resources {
#             limits = {
#               cpu    = "0.5"
#               memory = "512Mi"
#             }
#             requests = {
#               cpu    = "250m"
#               memory = "50Mi"
#             }
#           }

#           liveness_probe {
#             http_get {
#               path = "/"
#               port = 80

#               http_header {
#                 name  = "X-Custom-Header"
#                 value = "Awesome"
#               }
#             }

#             initial_delay_seconds = 3
#             period_seconds        = 3
#           }
#         }
#       }
#     }
#   }
# }