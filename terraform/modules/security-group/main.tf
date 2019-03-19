resource "aws_security_group" "this" {
  description = "${var.name}"
  vpc_id      = "${var.vpc_id}"

  tags = {
    "Name" = "${var.name}"
  }
}

#########################
# Ingress Rule
#########################
resource "aws_security_group_rule" "ingress_with_cidr_block" {
  count = "${length(var.ingress_with_cidr_block_rules)}"

  type = "ingress"

  security_group_id = "${aws_security_group.this.id}"

  cidr_blocks = "${split(",", lookup(var.ingress_with_cidr_block_rules[count.index], "cidr_blocks"))}"

  from_port   = "${lookup(var.ingress_with_cidr_block_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.ingress_with_cidr_block_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.ingress_with_cidr_block_rules[count.index], "protocol")}"
  description = "${var.name}"
}

resource "aws_security_group_rule" "ingress_with_security_group" {
  count = "${var.number_of_computed_ingress_with_source_security_group_rules}"

  type = "ingress"

  security_group_id = "${aws_security_group.this.id}"

  source_security_group_id = "${lookup(var.ingress_with_security_group_rules[count.index], "source_security_group_id")}"

  from_port   = "${lookup(var.ingress_with_security_group_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.ingress_with_security_group_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.ingress_with_security_group_rules[count.index], "protocol")}"
  description = "${var.name}"
}

#########################
# Egress Rule
#########################
resource "aws_security_group_rule" "egress" {
  type = "egress"

  security_group_id = "${aws_security_group.this.id}"

  cidr_blocks = ["0.0.0.0/0"]

  from_port = 0
  to_port   = 0
  protocol  = "-1"
}
