resource "kubernetes_cron_job" "my_cronjob" {
  metadata {
    name = "my-cronjob"
  }
  
  spec {

    schedule = "*/5 * * * *"

    job_template {
      metadata {}
      spec {
        backoff_limit = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "busybox"
              image   = "busybox"
              command = ["echo", "Hello", "World"]
            }
          }
        }
      }
    }
  }
}
