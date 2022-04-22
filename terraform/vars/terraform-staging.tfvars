environment               = "staging"
log_level                 = "info"
desired_count             = 1
auto_scaling_min_capacity = 1
auto_scaling_max_capacity = 15

healthcheck_path = "/v1/fw_service_template/healthcheck" // TODO
healthcheck_sns_emails = [] // TODO