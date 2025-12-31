module "networking" {
  source = "./networking"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  cidr_public_subnet = var.cidr_public_subnet
  eu_availability_zone = var.eu_availability_zone
  cidr_private_subnet = var.cidr_private_subnet
}


module "security_group" {
  source = "./security-groups"
  vpc_id = module.networking.dev_proj_1_vpc_id
  ec2_sg_name = "dev-proj-1-jenkins-ec2-sg"
  ec2_jenkins_sg_name = "Allow port 8080 for jenkins access"
}


module "jenkins" {
  source = "./jenkins"
  ami_id = var.ec2_ami_id
  instance_type = "t2.medium"
  tag_name = "Jenkins-Ubuntu Linux Ec2" // optional
  public_key = var.public_key
  subnet_id = tolist(module.networking.dev_proj_1_public_subnets)[0]
  sg_for_jenkins = [module.security_group.sg_ec2_sg_ssh_http_id,module.security_group.sg_ec2_jenkins_port_8080_id]
  enable_public_ip_address = true
  user_data_install_jenkins = templatefile("./jenkins-runner-script/jenkins-installer.sh", { 
    
    TERRAFORM_VERSION = "1.6.5"
     # jenkins_port = var.jenkins_port
  })
}

module "lb_target-group" {
  source = "./lb-target-group"
  lb_target_group_name = "jenkins-lb-target-group"
  lb_target_group_port = 8080
  lb_target_group_protocol = "HTTP"
  vpc_id = module.networking.dev_proj_1_vpc_id
  ec2_instance_id = module.jenkins.jenkins_ec2_instance_ip
}


module "load_balancer" {
  source = "./load-balancer"
  lb_name = "dev-proj-1-lb"
  is_external = false
  lb_type ="application"
  sg_enable_ssh_https = module.security_group.sg_ec2_sg_ssh_http_id
  subnet_ids = tolist(module.networking.dev_proj_1_public_subnets)
  tag_name = "dev_proj_1_lb"
  lb_target_group_arn = module.lb_target-group.dev_proj_1_lb_target_group_arn
  ec2_instance_id = module.jenkins.jenkins_ec2_instance_ip
  lb_listener_port = 80
  lb_listener_protocol = "HTTP"
  lb_listener_default_action = "forward"
  # lb_https_listener_port = 443
  # lb_https_listener_protocol = "HTTPS"
  # dev_proj_1_acm_arn = module.aws-certification-manager.dev_proj_1_acm_arn
  lb_target_group_attachment_port = 8080
}


# module "aws-certification-manager" {
#   source = "./aws-certificate-manager"
#   domain_name = "jenkins.devops1.kshitiz.com"
#   hosted_zone_id = module.hosted-zone.hosted_zone_id
#   }



module "hosted-zone" {
  source = "./hosted-zone"
  domain_name = "leduapops.duckdns.org"
  aws_alb_dns_name = module.load_balancer.aws_lb_dns_name
  aws_alb_zone_id = module.load_balancer.aws_lb_zone_id
}