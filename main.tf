data "aws_availability_zones" "all" {}

data "aws_acm_certificate" "fqdn" {
  domain   = "${var.dev_fqdn}"
}
data "template_file" "user_data" {
    template = "${file("${path.module}/user-data.sh")}"

    vars {
        server_port = "${var.server_port}"
        cluster_name = "${var.cluster_name}"
    }
}

resource "aws_iam_instance_profile" "instance_profile" {
  role = "${aws_iam_role.web_instance_role.name}"
}

resource "aws_iam_role" "web_instance_role" {

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = "${aws_iam_role.web_instance_role.name}"
}

resource "aws_iam_role_policy" "attach_instance_policy" {
  name = "attach-instance-role-policy"
  role = "${aws_iam_role.web_instance_role.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
         {
            "Effect": "Allow",
            "Action": [
                "codecommit:BatchGet*",
                "codecommit:Get*",
                "codecommit:Describe*",
                "codecommit:List*",
                "codecommit:GitPull"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchEventsCodeCommitRulesReadOnlyAccess",
            "Effect": "Allow",
            "Action": [
                "events:DescribeRule",
                "events:ListTargetsByRule"
            ],
            "Resource": "arn:aws:events:*:*:rule/codecommit*"
        },
        {
            "Sid": "SNSSubscriptionAccess",
            "Effect": "Allow",
            "Action": [
                "sns:ListTopics",
                "sns:ListSubscriptionsByTopic",
                "sns:GetTopicAttributes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LambdaReadOnlyListAccess",
            "Effect": "Allow",
            "Action": [
                "lambda:ListFunctions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMReadOnlyListAccess",
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers"
            ],
            "Resource": "*"
        },
         {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}


resource "aws_launch_configuration" "launch_config" {
	image_id = "${var.ami_id}"
	instance_type = "${var.instance_type}"
  	security_groups = ["${aws_security_group.instance.id}"]	
    iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"

	user_data = "${data.template_file.user_data.rendered}"

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_security_group" "instance" {
	name = "${var.cluster_name}-instance"
	ingress {
		from_port = "${var.server_port}"
		to_port = "${var.server_port}"
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
	}
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
        
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "web_asg" {
    name = "${var.cluster_name}-asg-instance"
	launch_configuration = "${aws_launch_configuration.launch_config.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
        
	load_balancers = ["${aws_elb.web_asg_elb.name}"]
	health_check_type = "ELB"
    health_check_grace_period = 3000

	min_size = "${var.min_size}" 
	max_size = "${var.max_size}"
        
    # 자동생성되는 ec2인스턴스의 Tag
	tag {
		key = "Name"
		value = "${var.cluster_name}-asg-instance"
		propagate_at_launch = true
	}
}

resource "aws_lb_cookie_stickiness_policy" "http_cookie" {
  name                     = "http-lb-policy"
  load_balancer            = "${aws_elb.web_asg_elb.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}
resource "aws_lb_cookie_stickiness_policy" "https_cookie" {
  name                     = "https-lb-policy"
  load_balancer            = "${aws_elb.web_asg_elb.id}"
  lb_port                  = 443
  cookie_expiration_period = 600
}

resource "aws_elb" "web_asg_elb" {
	name = "${var.cluster_name}-elb"
	security_groups = ["${aws_security_group.elb.id}"]
	availability_zones = ["${data.aws_availability_zones.all.names}"]

    cross_zone_load_balancing   = true
    idle_timeout                = 400
    # dev 환경에서는 비활성
    connection_draining         = false
    connection_draining_timeout = 400

    tags = {
        Name = "${var.cluster_name}-elb"
    }
	
	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
	}
	listener {
		lb_port = 443 
		lb_protocol = "https"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
        ssl_certificate_id = "${data.aws_acm_certificate.fqdn.arn}"
	}
	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "HTTP:${var.server_port}/elb-health-check"
	}
}

resource "aws_security_group" "elb" {
	name = "${var.cluster_name}-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = "${aws_security_group.elb.id}"

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_https_inbound" {
    type = "ingress"
    security_group_id = "${aws_security_group.elb.id}"

    from_port = 443
    to_port = 443 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id = "${aws_security_group.elb.id}"

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}




