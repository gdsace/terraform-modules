grafana_database_host     = "postgres"
grafana_database_port     = 1234
grafana_database_ssl_mode = "disable"
grafana_database_type     = "postgres"
grafana_fqdns             = "grafana.io"
grafana_vault_policies    = ["grafana"]

nomad_clients_node_class = "nomad"

vault_admin_path    = "secrets/grafana/admin"
vault_database_path = "postgres/creds/grafana"
