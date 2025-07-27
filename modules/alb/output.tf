output "alb_sg_id" {
    value = aws_security_group.alb.id
}

output "alb_end_point_anme" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.main.dns_name
}
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "patient_tg_arn" {
  description = "Target Group ARN for Patient service"
  value       = aws_lb_target_group.patient_service.arn
}

output "appointment_tg_arn" {
  description = "Target Group ARN for Appointment service"
  value       = aws_lb_target_group.appointment_service.arn
}
