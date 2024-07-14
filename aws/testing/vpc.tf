module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  cidr            = "10.0.0.0/20"
  azs             = ["eu-north-1a"]
  name            = "test-vpc-1"
  private_subnets = ["10.0.0.0/21"]
  public_subnets  = ["10.0.8.0/24"]
}

module "vpc2" {
  source          = "terraform-aws-modules/vpc/aws"
  cidr            = "10.0.16.0/20"
  azs             = ["eu-north-1a"]
  name            = "test-vpc-2"
  private_subnets = ["10.0.16.0/21"]
  public_subnets  = ["10.0.24.0/24"]
}

resource "aws_vpc_peering_connection" "peering_test" {
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = module.vpc2.vpc_id
  auto_accept = true
}
