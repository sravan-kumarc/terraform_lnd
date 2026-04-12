instance_type = "t3.small"
user_data = "nginx"

tags = {
  Environment = "prod"
  Name        = "lnd-node_prod"
  Project     = "lnd-node_prod"
}