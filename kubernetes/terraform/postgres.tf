# resource "docker_registry_image" "postgres_airflow" {
#     name = docker_image.postgres_airflow.name
#     keep_remotely = true
# }


# resource "docker_image" "postgres_airflow" {
#     name = "postgres-airflow"
#     build {
#         context = "${path.module}"
#         # tag = [ "${var.registry_url}/${name}" ]
#         dockerfile = "${path.module}/postgres.dockerfile"
#     }
#     triggers = {
#       dir_sha1 = filesha1("./airflow/postgres.dockerfile") 
#     }
# }