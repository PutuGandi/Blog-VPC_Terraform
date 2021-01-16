variable "aws_availability_zones" {
    description = "Availability zones"
    type        = list
    default     = [
        "ap-southeast-1a",
        "ap-southeast-1b"
    ]
}

variable "public_subnets" {
    description = "Public Subnet"
    type = list
    default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnets" {
    description = "Private Subnet"
    type = list
    default = ["10.0.3.0/24","10.0.4.0/24"]
}

variable "public_names" {
  description = "Private names"
  type        = list(string)
  default     = ["sn-public-a","sn-pubic-b"]
}

variable "private_names" {
  description = "Public names"
  type        = list(string)
  default     = ["sn-app-a","sn-app-b"]
}