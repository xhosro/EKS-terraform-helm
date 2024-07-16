provider "aws" {
  region = local.region
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}



# helm provider
# data resources autorized helm provider
# data resources wait until eks was previsioned, so its safe to run everyhing together.
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

# to initialize helm, we either use an auth token directly like this or we use exec & execute the command to take the token.
# in the second case we must install AWS CLI in the machine where we want to run the terraform, but not for first case.
# since we add helm provider, we need to initialize the terraform
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
    # exec {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   args        = ["eks", "get-token", "--cluster-name", "--ignore-not-after=0", data.aws_eks_cluster.default.id]
    #   command = "aws"
    # }
  }
}




