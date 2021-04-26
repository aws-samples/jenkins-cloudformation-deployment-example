# Configure Jenkins Agent

Setup a Kubernetes YAML template after you've built the agent image. In this example, we will be using the [k8sPodTemplate.yaml](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/k8s/k8sPodTemplate.yaml) file stored in the `k8s/` folder.

- The custom Jenkins Agent image we built earlier uses the Jenkins inbound-agent as the base image with the AWS CLI installed. Specify the container image in the file that will source the image with the associated AWS account and region.
- You can keep everything else as default, but depending on you specifications you can choose to modify the amount of resources that must be allocated.

```yaml
# Kubernetes YAML file
apiVersion: v1
kind: Pod
...
...
...
spec:
  serviceAccountName: jenkins-agent # Enter the service account name being used
  containers:
  - name: jenkins-agent
    image: <AWS-ACCOUNT-ID>.dkr.ecr.<AWS-REGION>.amazonaws.com/test-jenkins-agent:latest # Enter the jenkins inbound agent image.
...
...
...
```
