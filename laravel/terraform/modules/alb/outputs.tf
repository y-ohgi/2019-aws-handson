output "alb_arn" {
  description = "作成されたALBのARN"
  value       = "${aws_lb.this.arn}"
}

output "alb_dns_name" {
  description = "作成されたALBのDNS"
  value       = "${aws_lb.this.dns_name}"
}

output "http_listener_arn" {
  description = "作成されたHTTP用ALB ListenerのARN"
  value       = "${aws_lb_listener.http_listener.arn}"
}
