output "vpc_id" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.network.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
