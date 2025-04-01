#ECR setup 
resource "aws_ecr_repository" "weather-app-repo" {
  name                 = "weather-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Environment = "production"
  }
}

#ECS section of project 
# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

#ECS task Definition 
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "my-container"
    image     = "${aws_ecr_repository.weather-app-repo.repository_url}:latest"
    memory    = 512
    cpu       = 256
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}

#ECS using Fargate
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.Privsub1, var.Privsub2]
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = "my-container"
    container_port   = 5000
  }


}