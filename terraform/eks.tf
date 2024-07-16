# eks control plane

resource "aws_iam_role" "eks" {
  name = "${local.env}-${local.eks_name}-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
}
POLICY
  # we can use jsoncode built in function too
}


# attech policy to IAM role that will be used by the EKS
# for control manager IAM role ( demo-eks-cluster) we use the AmazonEKSClusterPolicy managed policy
resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}




# 
resource "aws_eks_cluster" "eks" {
  name     = "${local.env}-${local.eks_name}" # if we create multiple cluster in the same account
  version  = local.eks_version
  role_arn = aws_iam_role.eks.arn # attach aim role to the EKS cluster

  vpc_config {
    endpoint_private_access = false #https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
    endpoint_public_access  = true

    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id #https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
    ]
  }

  access_config {
    authentication_mode                         = "API" # https://docs.aws.amazon.com/eks/latest/userguide/auth-configmap.html
    bootstrap_cluster_creator_admin_permissions = true  # dafault is true but we enable it for defaults change in the future
  }                                                     # 

  depends_on = [aws_iam_role_policy_attachment.eks]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster



# kubernetes node group: k8s use it to run your application in worker nodes.

resource "aws_iam_role" "nodes" {
  name = "${local.env}-${local.eks_name}-eks-nodes"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# AmazonEKSWorkerNodePolicy managed policy that provide the core EC2 functionality permissions, it also allows running pod identity agent, which is used to grant granular access to your application.
# https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html



resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# we have to grant EKS access to modify the secondary ip address of configuration on your EKS worker nodes. 
# when we start to create loadbalancers é use IP mode to route traffic directly to the pod ip addresses.
# before that the cloud provider had to use nodeport behind the scenes when you create a service of type load balancer. now its direct by reducing the number of network hops, we reduce the latency of the requests.
# https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# AmazonEC2ContainerRegistryReadOnly IAM policy is used to grant EKS permission to pull Docker images fromm ECR.
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}



# https://docs.aws.amazon.com/eks/latest/userguide/worker.html
# EKS has three type of groups, the first is self-managed node group https://github.com/awslabs/amazon-eks-ami
# and the second is managed node group https://github.com/awslabs/amazon-eks-nodegroup
# managed node group is better for production environment. It's easier and managed automatically by the EKS control plane
# the thirs is AWS fargate, more easier but more expensive #https://docs.aws.amazon.com/eks/latest/userguide/fargate.html

# in the cloud its common to have a seprate spot node group which is cheaper, but cloud provider can take it away aat nytime
# # they are frequently use for batch or streaming jobs that in case of failure can start from previous savepoint
                    
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = local.eks_version
  node_role_arn   = aws_iam_role.nodes.arn # attach IAM role
  node_group_name = local.eks_node_group

  subnet_ids = [
    aws_subnet.private_zone1.id, # https://docs.aws.amazon.com/cur/latest/userguide/cur-data-transfers-charges.html
    aws_subnet.private_zone2.id  # in large companies, if we have kafka & many of services that read & write to from kafka from diffrent AZ its very expensive due to the data transfer costs between diffrent zone 
  ]

  capacity_type  = "ON_DEMAND" # or standard
  instance_types = ["t3.medium"] # t3.large

  # its create in auto-scalling group
  scaling_config {
    desired_size = 1 # will be updated by the cluster auto-scaller - we can use KEDA or Karpenter
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1 # for cluster upgrades
  }

  labels = {
    role = "general" # for using in pod affinity & node selectors
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]

  # terraform resources also allow you to ignore certain attributes of the objects you trying to crate
  # for example we we deploy cluster auto-scaler, it will manage the dezired size proerty of the auto-scalling group
  # which will conflict with the terraform state, so the solution is to ignore the desired size attribute after creating it.
  # Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

