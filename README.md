## About
Terraform module to bootstrap HTTPS Web Service with autoscaling ec2 instatnces within the default VPC on the multi-AZ.

Features:
* Default public subnets
* Default internet gateway
* MultiAZ mode for high availability 
* Classic Load Balancer with a SSL Certificate(443)
* Auto Scaling Group with a Launch Configuration
* Instance Profile for the EC2 Instance


Configs:
- Security Group for instances: {port: 80, cidr:`0.0.0.0/0`}
- Security Group for LB: {port: [80, 443], cidr:`0.0.0.0/0`}
- Auto Scaling Groups: {availability_zones: all, health_check_type: elb}
- Load Balancers: {cookie_stickyness: [80, 443], cookie_expiration_period: 600, listener:{lb_port:[80,443], instance_port:80}, health_check_target:"HTTP 80/elb-health-check"}



## Usage

Minimal setup: Domain name, min size(2) auto-scaling, multiAZ support, Seoul region

```
module "webserver_cluster" {
  source            = "github.com/espozbob/terraform-default-vpc-with-autoscaling-ec2"
  cluster_name      = "myproject"               // required
  dev_fqdn          = "*.example.com"           // required for Domain for ACM Certificate
}

//Create A record on the route53 for your hosted-zone ID

resource "aws_route53_record" "www" {
  zone_id = "(YOUR-DNS-HOSTED-ZONE-ID)"
  name    = "(HOST-NAME)"
  type    = "A"

  alias {
    name                   = "${module.webserver_cluster.elb_dns_name}"
    zone_id                = "${module.webserver_cluster.elb_zone_id}"
    evaluate_target_health = true
  }
}

output "elb_dns_name" {
    value = "${module.webserver_cluster.elb_dns_name}"
}
```


All options with default values:

```
module "webserver_cluster" {
    source              = "github.com/espozbob/terraform-default-vpc-with-autoscaling-ec2"
    aws_region          = "ap-northeast-2"
    dev_fqdn            = "*.example.com"
    ami_id              = "ami-123456789012345678"
    cluster_name        = "myproject"
    instance_type       = "t2.micro"
    min_size = 2
    max_size = 2
  
}


//Create A record on the route53

resource "aws_route53_record" "www" {
  zone_id = "(YOUR-DNS-HOSTED-ZONE-ID)"
  name    = "(HOST-NAME)"
  type    = "A"

  alias {
    name                   = "${module.webserver_cluster.elb_dns_name}"
    zone_id                = "${module.webserver_cluster.elb_zone_id}"
    evaluate_target_health = true
  }
}

output "elb_dns_name" {
    value = "${module.webserver_cluster.elb_dns_name}"
}

```

## Outputs

* `instance_role_id`
* `elb_dns_name`
* `elb_zone_id`
* `elb_security_group_id`
* `elb_name`
* `asg_name`
