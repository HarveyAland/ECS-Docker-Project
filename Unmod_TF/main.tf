#Networking for the Application
#Primary Region 
provider "aws" {
  region = "eu-west-2"
}


#VPC
resource "aws_vpc" "Primary_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "Primary-VPC"
    Environment = "production-primary"
  }
}

#Primary Subnets Public 
resource "aws_subnet" "Primary_sub_pub" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-1"
    Environment = "production-primary"
  }
}
resource "aws_subnet" "Primary_sub_pub_2" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-2"
    Environment = "production-primary"
  }
}
#Primary Subnets Private
resource "aws_subnet" "Primary_sub_priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name        = "Primary-Private-Subnet"
    Environment = "production-primary"
  }
}

resource "aws_subnet" "Primary_sub_priv2" {
  vpc_id = aws_vpc.Primary_vpc.id
  availability_zone = "eu-west-2b"
  cidr_block = "10.0.3.0/24"
  tags = {
    Name        = "Primary-Private-Subnet2"
    Environment = "production-primary"
  }
}

#Internet Gateway for Primary VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-IGW"
    Environment = "production-primary"
  }
}
#routetable for Primary VPC
resource "aws_route_table" "RT_prim" {
  vpc_id = aws_vpc.Primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name        = "Primary-Public-RT"
    Environment = "production-primary"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.Primary_sub_pub.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.Primary_sub_pub_2.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table" "RT_Prim_Priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-Private-RT"
    Environment = "production-primary"
  }
}  


resource "aws_route_table_association" "rtap1" {
  subnet_id      = aws_subnet.Primary_sub_priv.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}

resource "aws_route_table_association" "rtap2" {
  subnet_id      = aws_subnet.Primary_sub_priv2.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}


#Nat Gateway Setup for ECS Task to run whilst being isolated in private subnet

resource "aws_eip" "nat_eip" {
  domain = "vpc"  # Ensure the EIP is allocated for use in a VPC
  tags = {
    Name        = "Primary-NAT-EIP"
    Environment = "production-primary"
  }
}


# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.Primary_sub_pub.id  # Attach NAT GW to public subnet

  tags = {
    Name        = "Primary-NAT-Gateway"
    Environment = "production-primary"
  }
}

# Route for Private Subnets to use NAT Gateway for internet access
resource "aws_route" "nat_route" {
  route_table_id         = aws_route_table.RT_Prim_Priv.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

#Security groups
# Security Group for ALB (Application Load Balancer)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow inbound traffic from ALB to ECS Tasks"
  vpc_id      = aws_vpc.Primary_vpc.id

  # Allow inbound HTTP/HTTPS traffic to ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic (usually all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Security Group for ECS Tasks (restricted to only allow traffic from ALB)
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.Primary_vpc.id

  # Allow inbound traffic from the ALB security group on HTTP/HTTPS ports
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Only allow traffic from ALB
  }



  # Allow outbound traffic (usually all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#ALB Section
# Application Load Balancer
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.Primary_sub_pub.id, aws_subnet.Primary_sub_pub_2.id]
  enable_deletion_protection = false

  tags = {
    Name        = "ECS-ALB"
    Environment = "production"
  }
}

# ALB Listener
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
  type             = "forward"
  target_group_arn = aws_lb_target_group.alb_target_group.arn
}
}


# Target Group for ECS Service
resource "aws_lb_target_group" "alb_target_group" {
  name        = "ecs-target-group"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"  # For Fargate, use IP target type
  vpc_id = aws_vpc.Primary_vpc.id
  
  health_check { 
    protocol            = "HTTP"
    path                = "/health"  # Health check URL for ECS tasks
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "ECS Target Group"
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
  cpu                       = "256"
  memory                    = "512"
  network_mode              = "awsvpc"

  container_definitions = jsonencode([{
    name      = "my-container"
    image     = "${aws_ecr_repository.weather-app-repo.repository_url}:latest"
    memory    = 512
    cpu       = 256
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
      protocol      = "tcp"
    }]
  }])
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}


#ECS using Fargate
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2  # desired count of running tasks

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.Primary_sub_priv.id, aws_subnet.Primary_sub_priv2.id]
    assign_public_ip = false  # Fargate tasks don't require public IPs
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "my-container"
    container_port   = 5000  
  }

  depends_on = [
    aws_lb_listener.ecs_listener
  ]
}


#ECR setup 
resource "aws_ecr_repository" "weather-app-repo" {
  name = "weather-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "production"
  }
}


# IAM section

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Attach policies to ECS Task Role (example: S3 and CloudWatch access)
resource "aws_iam_role_policy_attachment" "ecs_task_role_s3_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_cloudwatch_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ecr_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        } 
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Attach AWS-managed policy for ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# New IAM Role for Pushing to ECR
resource "aws_iam_role" "ecr_push_role" {
  name = "ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"  # Adjust the principal as needed (e.g., your IAM user or role)
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Custom Policy for Pushing to ECR
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "ecr-push-policy"
  description = "Allows pushing Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the ECR Push Policy to the ECR Push Role
resource "aws_iam_role_policy_attachment" "ecr_push_policy_attachment" {
  role       = aws_iam_role.ecr_push_role.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}