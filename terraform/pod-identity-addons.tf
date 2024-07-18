resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
}

# to find the latest version of any specific addon, run : 
# aws eks describe-addon-versions --region eu-west-1 --addon-name eks-pod-identity-agent 
# make sure addon is running : kubectl get pods -n kube-system
# or : kubectl get daemonset eks-pod-identity-agent -n kube-system
