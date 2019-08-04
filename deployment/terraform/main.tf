provider "aws" {
  version = "1.59"
}

resource "aws_vpc" "hellovpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "dedicated"
}

resource "aws_subnet" "Priv" {
  vpc_id     = "${aws_vpc.hellovpc.id}"
  cidr_block = "10.0.1.0/24"
}
resource "aws_subnet" "Pub" {
  vpc_id     = "${aws_vpc.hellovpc.id}"
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.hellovpc.id}"
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.hellovpc.id}"
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = "${aws_internet_gateway.gw.id}"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.Pub.id}"
  route_table_id = "${aws_route_table.r.id}"
}


# The elastic beanstalk application
resource "aws_elastic_beanstalk_application" "hello_world" {
  name        = "${var.application_name}"
  description = "Hello_World"
}

data "aws_elastic_beanstalk_solution_stack" "latest" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux (.*) running Python 3$"
}



#manual security group added for EBS
resource "aws_security_group" "internal-ELB" {
  name        = "internal-ELB"
  description = "Allow Https inbound traffic for internal ELB"
  vpc_id      = "${aws_vpc.hellovpc.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["35.244.189.130"]
  }

  tags {
    Name          = "Hello_World"
    environment   = "Prod"
  }
}

resource "aws_elb" "elb" {
  name               = "helloelb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = ["${aws_elastic_beanstalk_environment.helloservice.loadbalancer.instances.instances}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

# The test environment
resource "aws_elastic_beanstalk_environment" "helloservice" {
  name        = "${var.environment_name}"
  application = "${aws_elastic_beanstalk_application.hello_world.name}"
  solution_stack_name = "${data.aws_elastic_beanstalk_solution_stack.latest.name}"
  tier                   = "WebServer"
  wait_for_ready_timeout = "40m"

  tags {
    region                 = "${var.aws_region}"
    app                    = "Hello_world"
    environment   = "Prod"
  }

  # This is the VPC that the instances will use.
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.hellovpc.id}"
  }

  # This is the subnet of the ELB
  # Public subnets only
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.Priv.name}}"
  }

  # This is the subnets for the instances and should be private subnets
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.Priv.name}"
  }


  # Start Environment Variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = "5000"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATASOURCE_URL"
    value     = "${aws_db_instance.hellodb.endpoint}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATASOURCE_USERNAME"
    value     = "${aws_db_instance.hellodb.username}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATASOURCE_PASSWORD"
    value     = "${aws_db_instance.hellodb.password}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV_TYPE"
    value     = "PROD"
  }


  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = "${var.aws_region}"
  }
 
  # Rolling update of Environment
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Fixed"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }


  # End Environment Variables

  # Start ELB settings
  # Are the load balancers multizone?
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }
  # Enable connection draining.
  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingEnabled"
    value     = "true"
  }
  # HTTPS listener
  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "5000"
  }
  #Listener Settings
  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstanceProtocol"
    value     = "HTTP"
  }
  # HTTP listener
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "LoadBalancerHTTPPort"
    value     = "80"
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "InstancePort"
    value     = "5000"
  }
  #Listener Settings
  setting {
    namespace = "aws:elb:listener"
    name      = "InstanceProtocol"
    value     = "HTTP"
  }
  # ELB Healthcheck - this is a sample; your application should have some sort of "ping" functionality
  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "HTTP:5000/healthcheck"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.internal-ELB.id}"
  }
  

  # End ELB settings


  # Start AutoScalingGroup Settings

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = "Any 2"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Cooldown"
    value     = "3000"                #5Minutes
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "5"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  # End AutoScalingGroup Settings


  # Start Autoscaling Trigger Settings

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "10"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "70"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerBreachScaleIncrement"
    value     = "-1"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperBreachScaleIncrement"
    value     = "1"
  }

  # End Autoscaling Trigger Settings

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }
  #Cloud watch logs settings
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "30"
  }
  # Start health reporting settings
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
  setting {
    namespace = "aws:elasticbeanstalk:xray"
    name      = "XRayEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "false"
  }
}

resource "aws_db_instance" "hellodb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "ajinkay"
  password             = "56455shahsodnsk444555"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "${aws_db_subnet_group.dbsub.id}"
  vpc_security_group_ids = "${aws_vpc.hellovpc.id}"
}
resource "aws_db_subnet_group" "dbsub" {
  name       = "main"
  subnet_ids = ["${aws_subnet.Priv.id}"]
}