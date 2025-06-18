output "alb_dns_name" {
  value       = aws_lb.lamp_alb.dns_name
  description = "DNS name of the application load balancer"
}

output "web_sg_id" {
  value       = aws_security_group.web_sg.id
  description = "ID of the web security group"
}

output "asg_name" {
  value = aws_autoscaling_group.lamp_asg.name
}

