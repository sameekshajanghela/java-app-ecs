resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_policy_attachment" {
  name       = "ecs_task_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_task_role.name]
}




resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-application"
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"] 

  container_definitions = jsonencode([
    {
      name  = "springboot-container"
      image = "sameeksha09/spring-boot-docker:spring-docker" 
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}
resource "aws_ecs_service" "my_service" {
  name            = "my-service-name"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE" 
  desired_count   = 1
  network_configuration {
    subnets = ["subnet-00f3eb62d3772bac6"] 
    security_groups = ["sg-0628acfb0983dd05d"] 
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "springboot-container"
    container_port   = 8080
  }
}
resource "aws_lb" "my_lb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-00f3eb62d3772bac6", "subnet-0c59160d6ff1c6f8b"]
 }

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = "vpc-0966adc7f554a7ac4" 
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"


  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

