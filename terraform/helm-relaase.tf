# metrics-server
# there is a couple of ways to override variables using the set block or yaml file
# we can use too the terraform template built-in function to create a yaml template and override some variables in there for dynamic purposes. like Aws account number or IAM role Arn
resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [aws_eks_node_group.general]
}

# for verfication metric server is up & running : kubectl get pods -n kube-system
# or fetch some logs é make sure there is no errors :
# kubectl logs -l app.kubernetes.io/instance=metric-server -f -n kube-system
# trying to get metrics by using : kubectl top pods/nodes -n kube-system

