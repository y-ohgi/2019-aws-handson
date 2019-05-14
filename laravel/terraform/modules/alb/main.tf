#########################
# Application LoadBalancer
#########################
resource "aws_lb" "this" {
  load_balancer_type = "application"

  name            = "${var.name}"
  security_groups = ["${var.security_groups}"]
  subnets         = ["${var.subnets}"]
}

#########################
# HTTP Listener
#########################
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ng"
      status_code  = "503"
    }
  }
}
