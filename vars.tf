
variable "aws_region" {
	description = "The region of the AWS"
	default = "ap-northeast-2"
}

variable "dev_fqdn" {
    description = "The FQDN for DEV SSL Certification"
}

variable "server_port" {
	description = "The port the sever will use for the http requests"
	default = "80"
}
variable "ami_id" {
	description = "최신 배포된 AMI 이미지 아이디"
    default = "ami-06e7b9c5e0c4dd014"
}
variable "cluster_name" {
    description = "모든 클러스터에 사용되는 리소스들의 구분이름"
}
variable "remote_state_bucket" {
    description = "데이터베이스의 상태정보가 있는 S3 버킷명"
}
variable "db_remote_state_key" {
    description = "데이터베이스의 상태정보가 있는 S3의 파일명"
}
variable "webserver_remote_state_key" {
    description = "웹서버의 상태정보가 있는 S3의 파일명"
}
variable "instance_type" {
    description = "EC2 인스턴스 타입(예. t2.micro)"
    default = "t2.micro"
}
variable "min_size" {
    description = "오토스케일링 그룹의 EC2 인스턴스 최소 개수"
    default = 2
}
variable "max_size" {
    description = "오토스케일링 그룹의 EC2 인스턴스 최대 개수"
    default = 2
}
