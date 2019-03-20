# Providerの設定。
#XXX: AWS Providerを使用してAWSのAPIを有効化し、ap-norheast-1(東京)リージョンへプロビジョニングを実行する
provider "aws" {
  region = "ap-northeast-1"
}

# 変数の宣言
variable "name" {
  description = "各種リソースの命名"
  default     = "handson"
}

data "aws_caller_identity" "self" {}

data "aws_region" "current" {}

#########################
# VPC
#########################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
  }
}

#########################
# Aurora MySQL
#########################
data "aws_ssm_parameter" "db_username" {
  name = "/handson/db/username"
}

data "aws_ssm_parameter" "db_password" {
  name = "/handson/db/password"
}

module "sg_db" {
  source = "./modules/security-group"

  name   = "${var.name}_db"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_with_cidr_block_rules = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/16"
    },
  ]
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name}-aurora-mysql5-7"
  family = "aurora-mysql5.7"
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-aurora-mysql5-7"
  family = "aurora-mysql5.7"
}

module "db" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name           = "${var.name}"
  engine         = "aurora-mysql"
  engine_version = "5.7.12"

  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.this.name}"
  db_parameter_group_name         = "${aws_db_parameter_group.this.name}"

  subnets = ["${module.vpc.private_subnets}"]
  vpc_id  = "${module.vpc.vpc_id}"

  instance_type = "db.t3.small"

  database_name = "${var.name}"
  username      = "${data.aws_ssm_parameter.db_username.value}"
  password      = "${data.aws_ssm_parameter.db_password.value}"
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/handson/db/endpoint"
  type  = "String"
  value = "${module.db.this_rds_cluster_endpoint}"
}

#########################
# ALB
#########################
module "sg_alb" {
  source = "./modules/security-group"

  name   = "${var.name}_alb"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_with_cidr_block_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "alb" {
  source = "./modules/alb"

  name = "${var.name}"

  security_groups = ["${module.sg_alb.this_security_group_id}"]
  subnets         = ["${module.vpc.public_subnets}"]
}

#########################
# ECS
#########################
resource "aws_ecs_cluster" "this" {
  name = "${var.name}"
}

data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars = {
    tag = "latest"

    account_id = "${data.aws_caller_identity.self.account_id}"
    region     = "${data.aws_region.current.name}"
    name       = "${var.name}"
  }
}

module "sg_ecs_service" {
  source = "./modules/security-group"

  name   = "${var.name}_ecs_service"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_with_cidr_block_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/16"
    },
  ]
}

module "service" {
  source = "./modules/ecs-service"

  container_definitions = "${data.template_file.container_definitions.rendered}"

  name    = "${var.name}"
  vpc_id  = "${module.vpc.vpc_id}"
  subnets = "${module.vpc.private_subnets}"

  ecs_cluster_name        = "${aws_ecs_cluster.this.name}"
  service_desired_count   = 1
  service_security_groups = ["${module.sg_ecs_service.this_security_group_id}"]

  alb_listener_arn = "${module.alb.http_listener_arn}"
}

#########################
# Outputs
#########################
output "dns_name" {
  value = "${module.alb.alb_dns_name}"
}
