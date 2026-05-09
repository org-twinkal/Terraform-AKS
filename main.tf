resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.name}-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "twinkal${local.name}"
  node_resource_group = "nodegroup_rg"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = "nodegroup${local.name}"
    node_count           = 3
    vm_size              = "Standard_B2s_v2"
    vnet_subnet_id       = azurerm_subnet.sub.id
    min_count            = 3
    max_count            = 5
    auto_scaling_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }

  tags = local.tags
}

resource "kubectl_manifest" "namespace" {
  for_each = fileset("${path.module}/k8s-manifests/namespace", "*.yml")

  yaml_body = file("${path.module}/k8s-manifests/namespace/${each.value}")

  depends_on = [ azurerm_kubernetes_cluster.aks ]
}

resource "helm_release" "argocd" {
  name = "argocd"
  namespace = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"

  depends_on = [ kubectl_manifest.namespace ]
}

resource "kubectl_manifest" "first-deployment" {
  for_each = fileset("${path.module}/k8s-manifests/first-deploy", "*.yml")

  yaml_body = file("${path.module}/k8s-manifests/first-deploy/${each.value}")

  depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "chatapp" {
  for_each = fileset("${path.module}/k8s-manifests/argocd/root-app", "*.yml")

  yaml_body = file("${path.module}/k8s-manifests/argocd/root-app/${each.value}")

  depends_on = [ kubectl_manifest.first-deployment ]
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  create_namespace = true
}

resource "kubectl_manifest" "ingress" {
  for_each = fileset("${path.module}/chatapp-gitops/ingress", "*.yml")

  yaml_body = file("${path.module}/chatapp-gitops/ingress/${each.value}")

  depends_on = [ helm_release.ingress_nginx ]
}