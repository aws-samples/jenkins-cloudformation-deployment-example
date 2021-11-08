# Deploy Jenkins Application

After building both images, navigate to the `k8s/` directory, modify the manifest file for the Jenkins image, and then execute the Jenkins [manifest.yaml](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/k8s/manifest.yaml) template to setup the Jenkins application. *(Note: This Jenkins application is not configured with a persistent volume storage. Therefore, you will need to establish and configure this template to fit that requirement).*

- Update kubeconfig and set the context of the cluster

```bash
# Update kubeconfig to select the cluster to use
~ aws eks update-kubeconfig https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/stackinfo?stackId=arn%3Aaws%3Acloudformation%3Aus-west-2%3A926543670953%3Astack%2Feksctl-adorable-creature-1636316651-cluster%2Fae0c23f0-4008-11ec-997d-02cde7e17779 --region us-west-2
```

```yaml
# Kubernetes YAML file
apiVersion: apps/v1
kind: Deployment
...
...
...
spec:
  serviceAccountName: jenkins-manager # Enter the service account name being used
  containers:
  - name: jenkins-manager
    image: 926543670953.dkr.ecr.us-west-2.amazonaws.com/Ayo-jenkins-manager:latest # Enter the jenkins manager image
...
...
...
```

```bash
# Apply the kubernetes manifest to deploy the Jenkins Manager application
~ kubectl apply -f manifest.yaml
```

- Run the following command to make sure your EKS pods are ready and running. We have 1 pod, hence the 1/1 output below. Fetch and navigate to the Load Balancer URL. The next step is to get the password to login to Jenkins as the **admin** user. Run the following command below to get the auto generated initial Jenkins password. Please update your password after logging in.

```bash
# Fetch the Application URL or navigate to the AWS Console for the Load Balancer
~ kubectl get svc -n jenkins

# Verify that jenkins deployment/pods are up running
~ kubectl get pods -n jenkins

# Replace with jenkins manager pod name and fetch Jenkins login password
~ kubectl exec -it pod/<JENKINS-MANAGER-POD-NAME> -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```
