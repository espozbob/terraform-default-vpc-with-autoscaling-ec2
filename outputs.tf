
output "instance_role_id" {
	value = "${aws_iam_role.web_instance_role.id}"
}
output "elb_dns_name" {
	value = "${aws_elb.web_asg_elb.dns_name}"
}
output "elb_zone_id" {
	value = "${aws_elb.web_asg_elb.zone_id}"
}
output "elb_security_group_id" {
    value = "${aws_security_group.elb.id}"
}
output "elb_name" {
	value = "${aws_elb.web_asg_elb.name}"
}
output "asg_name" {
	value = "${aws_autoscaling_group.web_asg.name}"
}
