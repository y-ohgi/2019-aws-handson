provider "aws" {
  region = "ap-northeast-1"
}

variable "name" {
  type = "string"

  default = "handson"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "azs" {
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "domain" {
  type = "string"

  # default = "<YOU DOMAIN>"
}

#########################
# VPC
#   VPC, PublicSubnet, PrivateSubnet, IGW, RouteTable, NAT GW
#########################
module "network" {
  source = "./network"

  name = "${var.name}"

  azs = "${var.azs}"
}

#########################
# ACM
#########################
module "acm" {
  source = "./acm"

  name = "${var.name}"

  domain = "${var.domain}"
}

#########################
# ELB
#########################
module "elb" {
  source = "./elb"

  name = "${var.name}"

  vpc_id            = "${module.network.vpc_id}"
  public_subnet_ids = "${module.network.public_subnet_ids}"
  domain            = "${var.domain}"
  acm_id            = "${module.acm.acm_id}"
}

#########################
# RDS
#########################
data "aws_ssm_parameter" "db_name" {
  name = "/${var.name}/db/name"
}

data "aws_ssm_parameter" "db_username" {
  name = "/${var.name}/db/username"
}

data "aws_ssm_parameter" "db_password" {
  name = "/${var.name}/db/password"
}

module "rds" {
  source = "./rds"

  name = "${var.name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.private_subnet_ids}"

  database_name   = "${data.aws_ssm_parameter.db_name.value}"
  master_username = "${data.aws_ssm_parameter.db_username.value}"
  master_password = "${data.aws_ssm_parameter.db_password.value}"
}

#########################
# ECS
#########################
module "ecs_cluster" {
  source = "./ecs_cluster"

  name = "${var.name}"
}

data "aws_caller_identity" "current" {}

data "template_file" "container_definitions" {
  template = "${file("./container_definitions.json")}"

  vars = {
    tag = "latest"

    name = "${var.name}"

    account_id = "${data.aws_caller_identity.current.account_id}"
    region     = "${var.region}"

    db_host = "${module.rds.endpoint}"
  }
}

module "ecs_service" {
  source = "./ecs_service"

  name = "${var.name}"

  cluster_name = "${module.ecs_cluster.cluster_name}"

  container_definitions = "${data.template_file.container_definitions.rendered}"

  vpc_id             = "${module.network.vpc_id}"
  subnet_ids         = "${module.network.private_subnet_ids}"
  https_listener_arn = "${module.elb.https_listener_arn}"
}
