# Deploy EKS cluster 

## Horizontal pod autoscaler configuration

- usually, we would use CPU or memory usage metrics to deside when we need to scale up our app.
- in deployment or statefulset we must to add resources in the spec part (requests) for HPA object work normally.
- to use autoscaller, you need some metrics.

- `` kubectl apply -f k8s/hpa-app 

we can split in diffrent parts or terminal:
    watch -t kubectl get pods -n hpa 
    watch -t k8s/hpa kubectl get hpa -n hpa
    kubectl get svc -n hpa
    kubectl port-forward svc/myapp 8080 -n hpa
    curl "http://localhost:8080/api/cpu?index=44" # send request to generate fibonacci number witch is a cpu-intensive task, it will force our app to hit hpa target of 80% and create another pod, hpa scale it down after 5 or 10 minutes

    kubectl delete ns hpa


## EKS pod identities & cluster autoscaler

- cluster autoscaler is external addons for automatically scale up & down the pods
- it needs permissions to interact with AWS, before we use OpenId Connect provider that is complicated
- a new way is to use eks pod identity , to enable it, you can use EKS addons , you still need to create a IAM role for the kubernetes service account
- so we deploy eks pod identity agents as a daemonset
