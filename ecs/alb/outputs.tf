output "dns_name" {
    value = aws_lb.main.dns_name
}

output "target_group_frontend_arn" {
  value = aws_alb_target_group.frontend.arn
}

// output "target_group_metadata_arn" {
//   value = aws_alb_target_group.metadata.arn
// }

// output "target_group_search_arn" {
//   value = aws_alb_target_group.search.arn
// }
