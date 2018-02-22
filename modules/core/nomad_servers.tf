# --------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD SERVER NODES
# --------------------------------------------------------------------------------------------------

module "nomad_servers" {
  source = "github.com/lawliet89/terraform-aws-nomad//modules/nomad-cluster?ref=aws_autoscaling_attachment"

  ami_id = "${var.nomad_servers_ami_id}"

  cluster_name  = "${var.nomad_cluster_name}-server"
  instance_type = "${var.nomad_server_instance_type}"

  # You should typically use a fixed size of 3 or 5 for your Nomad server cluster
  min_size         = "${var.nomad_servers_num}"
  max_size         = "${var.nomad_servers_num}"
  desired_capacity = "${var.nomad_servers_num}"

  user_data = "${coalesce(var.nomad_servers_user_data, data.template_file.user_data_nomad_server.rendered)}"

  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.public_subnets}"

  ssh_key_name = "${var.ssh_key_name}"
  allowed_inbound_cidr_blocks = "${concat(list(module.vpc.vpc_cidr_block), var.nomad_servers_allowed_inbound_cidr_blocks)}"
  allowed_ssh_cidr_blocks = "${var.allowed_ssh_cidr_blocks}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  health_check_type = "ELB"
}

# --------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES FOR CONSUL
# To allow our server Nodes to automatically discover the Consul servers, we need to give them the
# IAM permissions from
# the Consul AWS Module's consul-iam-policies module.
# --------------------------------------------------------------------------------------------------

module "consul_iam_policies_servers" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-iam-policies?ref=v0.1.0"

  iam_role_id = "${module.nomad_servers.iam_role_id}"
}

# --------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH NOMAD SERVER NODE WHEN IT'S BOOTING
# This script will configure and start Nomad
# --------------------------------------------------------------------------------------------------

data "template_file" "user_data_nomad_server" {
  template = "${file("${path.module}/user_data/user-data-nomad-server.sh")}"

  vars {
    num_servers       = "${var.nomad_servers_num}"
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.consul_cluster_name}"
  }
}
