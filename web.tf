#Deploy Wordpress instances

#Reference to bash script which prepares xenial image
data "template_file" "wpdeploy"{
  template = "${file("./webconfig.cfg")}"

  vars = {
    db_ip = "${aws_db_instance.wpdb.address}"
    db_user = "${var.db_user}"
    db_password = "${var.db_password}"
  }
}

data "template_cloudinit_config" "wpdeploy_config" {
  gzip = false
  base64_encode = false

  part {
    filename     = "webconfig.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.wpdeploy.rendered}"
  }
}


resource "aws_instance" "web-server" {
  ami = "${var.web_ami}"
  # The public SG is added for SSH and ICMP
  vpc_security_group_ids = ["${aws_security_group.web-sec.id}", "${aws_security_group.allout.id}"]
  instance_type = "${var.web_instance_type}"
  # Attaching to first web subnet for now, until NLB target group issue can be resolved
  subnet_id = "${aws_subnet.web_subnet1.id}"
  # my private key for testing
  #key_name = "win3_aws"

  tags = {
    Name = "AZ 1 web-server-${count.index}"
  }
  count = "${var.web_number}"
  depends_on = ["aws_db_instance.wpdb"]
  user_data = "${data.template_cloudinit_config.wpdeploy_config.rendered}"
}


resource "aws_security_group" "web-sec" {
  name = "webserver-secgroup"
  vpc_id = "${aws_vpc.app_vpc.id}"

  # Internal HTTP access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #ssh from anywhere (unnecessary)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ping access from anywhere
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# allow all egress traffic (needed for server to download packages)
resource "aws_security_group" "allout" {
  name = "allout-secgroup"
  vpc_id = "${aws_vpc.app_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
