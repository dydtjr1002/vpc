provider "aws" {
  region = "ap-northeast-2"
}

module "obs-vpc" {
  source = "./vpc"
}

module "obs-cluster" {
  source = "./eks"
  eks-vpc-id = module.obs-vpc.eks-vpc-id
  pub-sub1-id = module.obs-vpc.pub-sub1-id
  pub-sub2-id = module.obs-vpc.pub-sub2-id  
  pri-sub1-id = module.obs-vpc.pri-sub1-id
  pri-sub2-id = module.obs-vpc.pri-sub2-id
}