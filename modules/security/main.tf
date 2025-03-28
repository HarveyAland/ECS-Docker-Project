#Security groups
# Security Group for ALB (Application Load Balancer)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow inbound traffic from ALB to ECS Tasks"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP/HTTPS traffic to ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  from_port   = 443  # Add this block
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  # Allow outbound traffic (usually all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS Tasks (restricted to only allow traffic from ALB)
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from the ALB security group
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow outbound traffic (usually all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}