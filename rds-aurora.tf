########################
## Variables
########################

variable "environment_name" {
    default = "devops"
    description = "The name of the environment"
}

variable "vpc_id"{
	description = "The name of the environment"
}

variable "vpc_rds_subnet_ids" {
  description = "The ID's of the VPC subnets that the aurora cluster instances will be created in"
}

variable "vpc_rds_security_group_id" {
    description = "The ID of the security group that should be used for this aurora cluster"
}

variable "rds_master_username" {
  description = "The ID's of the VPC subnets that the aurora cluster instances will be created in"
}

variable "rds_master_password" {
  description = "The ID's of the VPC subnets that the aurora cluster instances will be created in"
}

variable "aurora_database_name" {
  default = "devops-rds"
  description = "The ID's of the VPC subnets that the aurora cluster instances will be created in"
}

########################
## Cluster
########################

resource "aws_rds_cluster" "aurora_cluster" {

    cluster_identifier            = "${var.environment_name}-aurora-cluster"
    database_name                 = "${var.aurora_database_name}"
    master_username               = "${var.rds_master_username}"
    master_password               = "${var.rds_master_password}"
    backup_retention_period       = 14
    preferred_backup_window       = "02:00-03:00"
    preferred_maintenance_window  = "wed:03:00-wed:04:00"
    db_subnet_group_name          = "${aws_db_subnet_group.aurora_subnet_group.name}"
    final_snapshot_identifier     = "${var.environment_name}-aurora-cluster"
    vpc_security_group_ids        = [
        "${var.vpc_rds_security_group_id}"
    ]

    tags {
        Name         = "${var.environment_name}-Aurora-DB-Cluster"
        ManagedBy    = "terraform"
        Environment  = "${var.environment_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {

    count                 = "${length(split(",", var.vpc_rds_subnet_ids))}"

    identifier            = "${var.environment_name}-aurora-instance-${count.index}"
    cluster_identifier    = "${aws_rds_cluster.aurora_cluster.id}"
    instance_class        = "db.t2.small"
    db_subnet_group_name  = "${aws_db_subnet_group.aurora_subnet_group.name}"
    publicly_accessible   = true

    tags {
        Name         = "${var.environment_name}-Aurora-DB-Instance-${count.index}"
        ManagedBy    = "terraform"
        Environment  = "${var.environment_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_db_subnet_group" "aurora_subnet_group" {

    name          = "${var.environment_name}-aurora-db-subnet-group"
    description   = "Allowed subnets for Aurora DB cluster instances"
    subnet_ids    = [
        "${split(",", var.vpc_rds_subnet_ids)}"
    ]

    tags {
        Name         = "${var.environment_name}-Aurora-DB-Subnet-Group"
        ManagedBy    = "terraform"
        Environment  = "${var.environment_name}"
    }

}

########################
## Output
########################

output "cluster_address" {
    value = "${aws_rds_cluster.aurora_cluster.endpoint}"
}
