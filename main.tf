terraform {
  backend "remote" {
    hostname = "my.scalr.com"
    organization = "org-sfgari365m7sck0"
    workspaces {
      name = "gke-wordpress"
    }
  }
}

provider "google" {
    project     = "${var.scalr_google_project}"
    credentials = "${var.scalr_google_credentials}"
    region      = var.region
}

data "google_container_cluster" "this" {
  name = "${var.cluster_name}"
  location = var.region
}

data "google_client_config" "current" {}

provider "kubernetes" {
  load_config_file = false
  host = "${data.google_container_cluster.this.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth.0.cluster_ca_certificate)
  token = "${data.google_client_config.current.access_token}"
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name = "mysql-pass"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_pod" "wordpress" {
  metadata {
    name = "${var.service_name}-pod"
    labels = {
      App = "${var.service_name}-pod"
    }
  }
  spec {
    container {
      image = "tutum/wordpress"
      name  = "${var.service_name}-ct"
      port {
        container_port = 80
      }
/*
      env {
        name  = "WORDPRESS_DB_HOST"
        value = aws_db_instance.default.endpoint
      }
*/
      env {
        name  = "WORDPRESS_DB_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.mysql.metadata[0].name
            key  = "password"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress_svc" {
  metadata {
    name = "${var.service_name}-svc"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.wordpress.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = "${kubernetes_service.wordpress_svc.load_balancer_ingress.0.ip}"
}

output "lb_hostname" {
  value = "${kubernetes_service.wordpress_svc.load_balancer_ingress.0.hostname}"
}
