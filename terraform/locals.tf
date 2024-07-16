locals {
    env     = "dev"
    region = "eu-west-1"
    zone1 = "eu-west-1a"
    zone2 = "eu-west-1b"
    eks_name = "demo"
    eks_version = "1.29" # https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/kubernetes-versions.html
    eks_node_group = "general" #cpu-optimized node group or memory-optimized node group or gpu node-group to run machine learning
}