variable "name" {
  description = "アプリケーションに使用する命名。	"
  default     = "myapp"
}

variable "tags" {
  description = "各リソースに付与するtag"
  default     = {}
}

variable "vpc_id" {
  type = "string"
}

variable "subnets" {
  type = "list"
}

variable "ecs_cluster_name" {
  type = "string"
}

#########################
# Task Definition
#########################
variable "container_definitions" {
  description = "JSONで記述されたタスク定義"
  type        = "string"
}

variable "port" {
  description = "トラフィックを流すポート"
  default     = "80"
}

variable "task_cpu" {
  description = "タスクのCPU"
  default     = 256
}

variable "task_memory" {
  description = "タスクのメモリ"
  default     = 512
}

variable "task_network_mode" {
  description = "タスクのネットワークモード"
  default     = "awsvpc"
}

variable "task_requires_compatibilities" {
  description = "タスクの起動タイプ e.g. 'FARGATE', 'ECS'"
  default     = "FARGATE"
}

variable "task_log_rotate_day" {
  description = "CloudWatch Logsの失効期間(日)"
  default     = "7"
}

#########################
# Service
#########################
variable "service_desired_count" {
  description = "Serviceのの初回起動数"
  default     = 1
}

variable "service_initial_delay_seconds" {
  description = "Service起動からトラフィックを流すまでのレイテンシ(秒)"
  default     = "10"
}

variable "service_security_groups" {
  description = "ECS Serviceに登録するセキュリティグループ一覧 e.g. ['sg-edcd9784','sg-edcd9785']"
  type        = "list"
}

variable "service_enable_assign_public_ip" {
  description = "TaskにPublicIPをつけるか"
  default     = "false"
}

variable "service_deployment_controller" {
  description = "Serviceのデプロイ方法 e.g. 'ECS', 'CODE_DEPLOY'"
  default     = "ECS"
}

variable "alb_health_check_path" {
  description = "ヘルスチェックを行うパス"
  default     = "/"
}

variable "alb_health_check_matcher" {
  description = "ヘルスチェックの成功コード"
  default     = "200-399"
}

variable "alb_listener_arn" {
  type = "string"
}

variable "alb_listener_condition_field" {
  description = "Listenerからトラフィックを流すルール e.g. 'path-pattern', 'host-header'"
  default     = "path-pattern"
}

variable "alb_listener_condition_values" {
  description = "Listenerからトラフィックを流すアクション e.g. '/', 'example.com'"
  default     = ["*"]
}
