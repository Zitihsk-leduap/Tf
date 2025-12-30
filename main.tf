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


# module "lb-target-group" {
#   source = "./lb-target-group"
#   lb_target_group_name = "jenkins-lb-target-group"
#   # vpc_id = module.networking.dev_proj_1_vpc_id
#   lb_target_group_port = 8080
#   lb_target_group_protocol = "HTTP"
#   vpc_id = module.networking.dev_proj_1_vpc_id
#   ec2_instance_id = module.jenkins.jenkins_ec2_instance_ip
# }

module "lb_target-group" {
  source = "./lb-target-group"
  lb_target_group_name = "jenkins-lb-target-group"
  lb_target_group_port = 8080
  lb_target_group_protocol = "HTTP"
  vpc_id = module.networking.dev_proj_1_vpc_id
  ec2_instance_id = module.jenkins.jenkins_ec2_instance_ip
}
