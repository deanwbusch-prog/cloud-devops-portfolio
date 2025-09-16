variable "project"               { type = string }
variable "vpc_cidr"              { type = string }
variable "public_subnet_cidrs"   { type = list(string) }
variable "private_subnet_cidrs"  { type = list(string) }
variable "enable_vpc_flow_logs"  { type = bool }
