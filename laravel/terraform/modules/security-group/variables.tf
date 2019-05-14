variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "myapp"
}

variable "description" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  default     = ""
}

variable "ingress_with_cidr_block_rules" {
  description = "List of ingress rules"
  default     = []
}

variable "number_of_computed_ingress_with_source_security_group_rules" {
  description = "Number of computed ingress rules"
  default     = 0
}

variable "ingress_with_security_group_rules" {
  description = "List of ingress rules"
  default     = []
}
