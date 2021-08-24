# Deploy Jenkins Application

After building both images, navigate to the `k8s/` directory, modify the manifest file for the Jenkins image, and then execute the Jenkins [manifest.yaml](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/k8s/manifest.yaml) template to setup the Jenkins application. *(Note: This Jenkins application is not configured with a persistent volume storage. Therefore, you will need to establish and configure this template to fit that requirement).*

- Update kubeconfig and set the context of the cluster

```bash
# Update kubeconfig to select the cluster to use
~ aws eks update-kubeconfig <CLUSTER-NAME> --region <REGION-NAME>
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
    image: <AWS-ACCOUNT-ID>.dkr.ecr.<AWS-REGION>.amazonaws.com/test-jenkins-manager:latest # Enter the jenkins manager image
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
