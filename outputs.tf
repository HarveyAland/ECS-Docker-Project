output "ecr_repository_url" {
  value = module.ecr_ecs.ecr_repository_url
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}