locals {
  count_subnet_id = length(var.SUBNET_ID)
 
  }

locals {
  target_group = {
    # "t2.micro"   = "free tier"
    # "m5.large"   = "general purpose"
    # "c5.xlarge"  = "compute optimized"


    "healthy_threshold"  = 3
    "interval "           = 10
    "matcher"             = 200
    "path"              = "/"
    "port"                = "traffic-port"
    "protocol"            = "HTTP"
    "timeout"             = 3
    "unhealthy_threshold" = 2
  }
}



##All these should be used as variables
resource "aws_lb_target_group" "front" {
  name     = "application-front"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.VPCID
  health_check {
    enabled             = true
    healthy_threshold   = lookup ( local.target_group , "healthy_threshold")
    interval            = lookup ( local.target_group , "interval") 
    matcher             = lookup ( local.target_group , "matcher")
    path                = lookup ( local.target_group , "path")
    port                = lookup ( local.target_group , "port")
    protocol            = lookup ( local.target_group , "protocol")
    timeout             = lookup ( local.target_group , "timeout")
    unhealthy_threshold = lookup ( local.target_group , "unhealthy_threshold")
    
  }
}



resource "aws_lb_target_group_attachment" "attach-app1" {
  count            = length(var.instance)
  target_group_arn = aws_lb_target_group.front.arn
  target_id        = element(var.instance[*], count.index)
  port             = 80
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front.arn
  # port              = "80"
  # protocol          = "HTTP"
  count = length(var.port)
  port    = var.port[count.index]
  protocol  = var.protocol[count.index]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
  }
}

module "aws_security_group" {
  source      = "./modules/security_group"
  # sg_count = length(var.security_groups)
  name = var.security_groups
  description = var.secgroupdescription
  vpc_id      = var.VPCID

} 


resource "aws_security_group_rule" "ingress_rules" {

  count = length(var.ingress_rules)

  type              = "ingress"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_block]
  description       = var.ingress_rules[count.index].description
  # security_group_id = module.aws_security_group.id[count.index]
  security_group_id = module.aws_security_group.id
}



resource "aws_lb" "front" {
  name               = "EG-ALB-TEST"
  internal           = false
  load_balancer_type = "application"
  # security_groups    = [module.aws_security_group.id]
  security_groups    =  concat([module.aws_security_group.id] , var.existing_security_group_ids[*])
  # security_groups     = [module.security_group.id]
  subnets            = [for subnet in var.SUBNET_ID : subnet]
  

  enable_deletion_protection = true

  tags = merge(tomap(var.alb_tags),{ApplicationFunctionality = var.ApplicationFunctionality, 
      ApplicationOwner = var.ApplicationOwner, 
      ApplicationTeam = var.ApplicationTeam, 
      BusinessOwner = var.BusinessOwner,
      BusinessTower = var.BusinessTower,
      ServiceCriticality = var.ServiceCriticality,
      VPC-id = var.VPCID})
  }
