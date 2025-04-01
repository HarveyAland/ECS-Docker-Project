#ALB Section
# Application Load Balancer
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = [var.Pubsub1, var.Pubsub2]
  enable_deletion_protection = false

  tags = {
    Name        = "ECS-ALB"
    Environment = "production"
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "alb_target_group" {
  name        = "ecs-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ALB Listener for HTTP - No HTTPs as its a project deployment (No Domain Name, No Route 53 zone)
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
  type             = "forward"
  target_group_arn = aws_lb_target_group.alb_target_group.arn
}
}
