variable "region" {
  type        = string
  description = "Name of the region where you want to provision resources"
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "instance_tenancy" {
  type = string
}

variable "vpc_name" {
  type = string
}
variable "public_subnet_name" {
  type = string
}
variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "internet_gateway_name" {
  type = string

}
variable "public_route_table_name" {
  type = string
}

variable "nat_gateway_name" {
  type = string
}
variable "security_group_name" {
  type = string
}
variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "vmname_public" {
  type = string
}

variable "vmname_private" {
  type = string
}

variable "key_name" {
  type = string
}

variable "private_route_table_name" {
  type = string
}

variable "public_subnet_az" {
  type = string
}

variable "private_subnet_az" {
  type = string
}