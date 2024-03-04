resource "kubernetes_service" "airflow" {
    metadata {
        name = "airflow"
        # namespace = kubernetes_namespace.airflow.metadata[0].name
    }
    spec {
        type = "NodePort"
        selector = {
          app =  "airflow"
        }
        port {
            name = "web-server"
            port = 8080
            target_port = 8080
            node_port = 30008
        }
        port {
            name = "postgres"
            port = 5432
            target_port = 5432
            node_port = 30009
        }
    }
}

resource "kubernetes_deployment" "airflow" {
    metadata {
        name = "airflow"
        labels = {
            app = "airflow"
        }
        # namespace = kubernetes_namespace.airflow.metadata[0].name
    }
    spec {
        replicas = 1
        selector {
            match_labels = {
                app = "airflow"
            }
        }

        template {
            metadata {
                labels = {
                    app = "airflow"
                }
                # namespace = kubernetes_namespace.airflow.metadata[0].name
            }
            spec {
                container {
                    name = "airflow-webserver"
                    image_pull_policy = "IfNotPresent"
                    image = "rapidfort/airflow"
                    command = [ "/bin/sh"]
                    args = [ "-c", "airflow db init && airflow webserver"]
                    port {
                        container_port = 8080
                    }
                    env {
                        name = "AIRFLOW_SECRET_KEY"
                        value = "mysecretkey"
                    }
                    env {
                        name = "AIRFLOW_EXECUTOR"
                        value = "CeleryExecutor"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_NAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_USERNAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_PASSWORD"
                        value = "123"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_HOST"
                        value = "airflow"
                    }
                    env {
                        name = "AIRFLOW_USERNAME"
                        value = "user"
                    }
                    env {
                        name = "AIRFLOW_PASSWORD"
                        value = "123"
                    }
                    env {
                        name = "AIRFLOW_EMAIL"
                        value = "alexander.haugerud@gmail.com"
                    }
                    env {
                        name = "REDIS_HOST"
                        value = "airflow"
                    }
                    
                }
                container {
                    name = "airflow-scheduler"
                    image_pull_policy = "IfNotPresent"
                    image = "rapidfort/airflow-scheduler"
                    env {
                        name = "AIRFLOW_SECRET_KEY"
                        value = "mysecretkey"
                    }
                    env {
                        name = "AIRFLOW_EXECUTOR"
                        value = "CeleryExecutor"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_NAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_USERNAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_PASSWORD"
                        value = "123"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_HOST"
                        value = "airflow"
                    }
                    env {
                        name = "AIRFLOW_WEBSERVER_HOST"
                        value = "airflow"
                    }
                    env {
                        name = "REDIS_HOST"
                        value = "airflow"
                    }
                }
                container {
                    name = "airflow-worker"
                    image_pull_policy = "IfNotPresent"
                    image = "rapidfort/airflow-worker"
                    env {
                        name = "AIRFLOW_SECRET_KEY"
                        value = "mysecretkey"
                    }
                    env {
                        name = "AIRFLOW_EXECUTOR"
                        value = "CeleryExecutor"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_NAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_USERNAME"
                        value = "postgres"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_PASSWORD"
                        value = "123"
                    }
                    env {
                        name = "AIRFLOW_DATABASE_HOST"
                        value = "airflow"
                    }
                    env {
                        name = "AIRFLOW_WEBSERVER_HOST"
                        value = "airflow"
                    }
                    env {
                        name = "REDIS_HOST"
                        value = "airflow"
                    }
                }
                container {
                    name = "postgres"
                    image = "rapidfort/postgresql-official"
                    env {
                        name = "POSTGRES_PASSWORD"
                        value = "123"
                    }
                    # env {
                    #     name = "PGTZ"
                    #     value = "NOR"
                    # }
                    image_pull_policy = "IfNotPresent"
                    volume_mount {
                        name = "postgres-data"
                        mount_path = "/var/lib/postgresql/data"
                    }
                    port {
                        container_port = 5432
                    }
                }
                container {
                    name = "redis"
                    image = "rapidfort/redis"
                    env {
                        name = "ALLOW_EMPTY_PASSWORD"
                        value = "yes"
                    }
                    # volume_mount {
                    #   name = "redis-data"
                    #   mount_path = "/bitnami"
                    # }
                }
                volume {
                    name = "postgres-data"
                    persistent_volume_claim {
                        claim_name = kubernetes_persistent_volume_claim.airflow_pg_pvc.metadata[0].name
                    }
                }
                # volume {
                #     name = "redis-data"
                #     persistent_volume_claim {
                #         claim_name = kubernetes_persistent_volume_claim.airflow_redis_pvc.metadata[0].name
                #     }
                # }
            }   
        }
    }
}