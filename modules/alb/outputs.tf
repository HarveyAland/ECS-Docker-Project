
output "alb_tg_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}

output "alb_dns_name" {
  value = aws_lb.ecs_alb.dns_name  
}

output "ecs_listener" {
  value = aws_lb_listener.ecs_listener.arn
}