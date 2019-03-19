data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  # アカウントID
  account_id = "${data.aws_caller_identity.current.account_id}"

  # プロビジョニングを実行するリージョン
  region = "${data.aws_region.current.name}"
}

#########################
# Task Definition
#########################
resource "aws_ecs_task_definition" "this" {
  family = "${var.name}"

  container_definitions = "${var.container_definitions}"

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  task_role_arn      = "${aws_iam_role.task_execution.arn}"
  execution_role_arn = "${aws_iam_role.task_execution.arn}"
}

resource "aws_iam_role" "task_execution" {
  name = "${var.name}-TaskExecution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task_execution" {
  role = "${aws_iam_role.task_execution.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:${local.region}:${local.account_id}:parameter/*",
        "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:*",
        "arn:aws:kms:${local.region}:${local.account_id}:key/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = "${aws_iam_role.task_execution.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.name}/ecs"
  retention_in_days = "${var.task_log_rotate_day}"
}

#########################
# Service
#########################
resource "aws_ecs_service" "this" {
  name = "${var.name}"

  cluster                           = "${var.ecs_cluster_name}"
  task_definition                   = "${aws_ecs_task_definition.this.arn}"
  launch_type                       = "FARGATE"
  desired_count                     = "${var.service_desired_count}"
  health_check_grace_period_seconds = "${var.service_initial_delay_seconds}"

  network_configuration = {
    subnets          = ["${var.subnets}"]
    security_groups  = ["${var.service_security_groups}"]
    assign_public_ip = "${var.service_enable_assign_public_ip}"
  }

  deployment_controller = {
    type = "ECS"
  }

  load_balancer = [
    {
      container_name   = "nginx"
      container_port   = "${var.port}"
      target_group_arn = "${aws_lb_target_group.this.arn}"
    },
  ]

  # deployment_maximum_percent         = 200
  # deployment_minimum_healthy_percent = 100

  # lifecycle {
  #   ignore_changes = ["load_balancer"]
  # }
}

resource "aws_lb_target_group" "this" {
  #XXX 乱数を生成せずにnameプロパティを使用するとALBへの依存が発生し、apply後に当該Moduleだけ削除することができなくなる https://github.com/terraform-providers/terraform-provider-aws/issues/636

  # name = "${var.name}"

  vpc_id = "${var.vpc_id}"
  port   = "${var.port}"

  protocol    = "HTTP"
  target_type = "ip"

  health_check = {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    port                = 80
    path                = "/"
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true

    #XXX: nameプロパティを使用する場合はコメントアウト
    # ignore_changes        = ["name"]
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = "${var.alb_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.id}"
  }

  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}
