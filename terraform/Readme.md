##
we start with creating locals and provider, then vpc
terraform download all the providers used in the code and initialize the local state file, but in production you would use a remote state in an s3 bucket instead
- terraform init 

- aws configure 
we add access key & secret access ID

the best method is not to use long-lived credentials and instead use IAM roles with short-lived credentials like token 1hr,
because IAM users have long-term credentials like paasword & access key 

- cat ~/.aws/credentials
- cat ~/.aws/config


after creating network configuration , we create eks control plane and nodes groups

for connecting th the cluster: 

check if we have a right user: aws sts get-caller-identity 

next : we need to update the local kubeconfig with: 
   - aws eks update-kubeconfig \
    --region eu-west-1 \
    --name dev-demo
    # --profile developer
   
   - kubectl config view --minify

    - kubectl get nodes : if you run this that means you are the admin of cluster

    - make sure to have read/write access to everything :
      kubectl auth can-i "*" "*"

    - kubectl auth can-i get pods


