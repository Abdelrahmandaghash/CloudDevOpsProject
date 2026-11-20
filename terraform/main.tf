terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Use the first 2 availability zones of the region
data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source               = "./modules/network"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

module "server" {
  source    = "./modules/server"
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_ids[0]
  key_name  = var.key_name
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "ivolve-cluster"
  private_subnet_ids = module.network.private_subnet_ids
}

module "ecr" {
  source     = "./modules/ecr"
  repo_names = ["frontend", "auth", "roadmap"]
}
