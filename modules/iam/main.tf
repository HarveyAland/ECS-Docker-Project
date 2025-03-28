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

# Attach policies to ECS Task Role ( CloudWatch access)

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