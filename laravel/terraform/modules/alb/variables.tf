variable "name" {
  description = "アプリケーションに使用する命名。"
  default     = "myapp"
}

variable "tags" {
  description = "各リソースに付与するtag"
  default     = {}
}

variable "acm_arn" {
  description = "HTTPSを使用する場合に登録するACMのARN"
  default     = ""
}

variable "subnets" {
  description = "ALBを配置するサブネット一覧 e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f'"
  type        = "list"
}

variable "security_groups" {
  description = "ALBに登録するセキュリティグループ一覧 e.g. ['sg-edcd9784','sg-edcd9785']"
  type        = "list"
}

variable "idle_timeout" {
  description = "リクエストの最大アイドルタイム(秒)"
  default     = 60
}

variable "internal" {
  description = "ALBをVPC内専用にする"
  default     = false
}
