  module "eks_al2" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    cluster_name    = "obs-pri-cluster"
    cluster_version = "1.30"

    # EKS Addons
    cluster_addons = {
      coredns                = {}
      eks-pod-identity-agent = {}
      kube-proxy             = {}
      vpc-cni                = {}
    }

    vpc_id     = var.eks-vpc-id
    subnet_ids = [
      var.pri-sub1-id,
      var.pri-sub2-id
    ]

    eks_managed_node_groups = {
      obs-nodegroups = {
        # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
        ami_type       = "AL2_x86_64"
        instance_types = ["t3.medium"]

        min_size = 2
        max_size = 5
        # This value is ignored after the initial creation
        # https://github.com/bryantbiggs/eks-desired-size-hack
        desired_size = 2
      }
    }
    # Cluster access entry
    # To add the current caller identity as an administrator
    
    access_entries = {
      # One access entry with a policy associated
      access_myAccount = {
        kubernetes_groups = []
        principal_arn     = "arn:aws:iam::178020491921:user/user3"

        policy_associations = {
          AmazonEKSAdminViewPolicy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
            access_scope = {
              type       = "cluster"
            }
          }
          AmazonEKSAdminPolicy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
            access_scope = {
              type       = "cluster"
            }
          }
          AmazonEKSClusterAdminPolicy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type       = "cluster"
            }
          }
        }

      }
    }
    
    cluster_endpoint_public_access  = true
  }
