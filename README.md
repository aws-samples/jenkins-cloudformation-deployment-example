## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

# **Orchestrate Jenkins Workloads using Dynamic Pod Autoscaling with Amazon EKS**

In this blog post, we’ll demonstrate how to leverage [Jenkins](https://www.jenkins.io/) with [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) by running a Jenkins Manager within an EKS pod. By doing so, we can run Jenkins workloads by allowing Amazon EKS to spawn dynamic Jenkins Agent(s) to perform application and infrastructure deployment.

In the effort to setup our Amazon EKS cluster with Jenkins, we’ll use the [`eksctl`](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html) simple CLI tool for creating clusters on EKS. Then, we'll build both the Jenkins Manager and Jenkins Agent image. Afterwards, we’ll run a container deployment on our cluster to access the Jenkins application and use the dynamic Jenkins Agent pods to run pipelines & jobs.

## Solution Overview

 The following architecture illustrates the execution steps.

![Image: img/Jenkins-CloudFormation.png](img/Jenkins-CloudFormation.png)
*Figure 1. Solution Overview Diagram*

Disclaimer(s): *(Note: This Jenkins application is not configured with a persistent volume storage, therefore you will need to establish and configure this template to fit that requirement).*

To accomplish this deployment workflow we’re going to do the following:

- Centralized Shared Services account
   1. Deploy the Amazon EKS Cluster into a Centralized Shared Services Account.
   2. Create the Amazon ECR Repository for the Jenkins Manager and Jenkins Agent to store docker images.
   3. Deploy the kubernetes manifest file for the Jenkins Manager.

- Target Account(s)
  1. Establish a set of [AWS Identity and Access Management (IAM)](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) roles with permissions for cross-across access from the Share Services account into the Target account(s).

- Jenkins Application UI
  1. Jenkins Plugins - Install and configure the [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/) and [CloudBees AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/) from Manage Plugins *(You will not have to manually install this since it will be packaged and installed as part of the Jenkins image build).*
  2. Jenkins Pipeline Example - Fetch the Jenkinsfile to deploy an S3 Bucket with CloudFormation in the Target account using a Jenkins parameterized pipeline.

## Account Prerequisite(s)

The following below is the minimum requirement in order to ensure this solution will work.

- Shared Services Account: This is where the Amazon EKS Cluster will reside.
- Target Account: This is destination of the CI/CD pipeline deployments.

## Build Requirements

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [Docker CLI](https://docs.docker.com/get-docker/) - *Note: The docker engine must be running to build images.*
- [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
- [eksctl](https://github.com/weaveworks/eksctl)

## Build Requirements Setup

Verify if the AWS CLI was installed by executing this command in your terminal `aws --version`. If you have an existing account, and your machine is configured for programmatic access, then you can proceed to the next step. In this walkthrough, we’ll be using Administrator privileges for our deployment. Additionally, Amazon ECR requires that users must have permission to make calls to the `ecr:GetAuthorizationToken`. These privileges are for demonstration purposes only and not recommended for production. Before proceeding, please ensure that you've properly install all the build requirements necessary.

- Configure your [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) with the associated region. The following steps show how you can do this.

```bash
# Export access keys
~ export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
~ export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXX
~ export AWS_SESSION_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
~ export AWS_DEFAULT_REGION=<REGION-NAME>

### OR ###

# Export AWS credentials profile
~ export AWS_PROFILE=<PROFILE-NAME>
```

- Verify if the build requirements were installed correctly by executing the following commands below.

```bash
# Check docker version
~ docker --version

# Check kubectl version
~ kubectl version —client

# Check eksctl version
~ eksctl version

# Check aws-iam-authenticator version
~ aws-iam-authenticator version
```

## Create EKS Cluster

Verify that your AWS configuration is pointing to the correct region you want EKS deployed. If you do not specify the region, the AWS Profile you setup earlier will be used as the default for where the cluster will reside. The following parameters is an example which will vary based on your preference. If you choose to deploy with a different name, region, zone, or node capacity please modify accordingly.

- [Create an EKS Cluster using eksctl](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/feature/k8s/EKS.md)

```bash
# Verify that EKS nodes are up running
~ kubectl get nodes
```

## Create Cross-Account IAM Roles

Cross-account IAM roles allow users to securely access AWS resources in a target account, while maintaining observability of that AWS account. The cross-account IAM role includes a trust policy that allows AWS identities in another AWS account to assume the given role. This allows me the ability to create a role in one AWS account that delegates specific permissions to another AWS account.

- Create an IAM role that has a common name in each target account. The role name we've created for use is called `AWSCloudFormationStackExecutionRole`. The role must have permissions to perform CloudFormation actions and any actions pertaining to the resources that will be created. In our case, we will be creating and S3 Bucket using CloudFormation.
- This IAM role must also have an established trust relationship to the Shared Services account. In this case, the Jenkins Agent will be granted the ability to assume the role of the particular target account from the Shared Services account. See the images below.

![Image: img/pic-01.png](img/pic-01.png)
*Figure 2a. Create and IAM Role and Enter the Account ID of the Shared Services account*

![Image: img/pic-02.png](img/pic-02.png)
*Figure 2b. Create IAM Policy with CloudFormation and S3 actions*

![Image: img/pic-03.png](img/pic-03.png)
*Figure 2c. Review IAM Policy*

![Image: img/pic-04.png](img/pic-04.png)
*Figure 2d. Attach IAM Policy to IAM Role and complete IAM role creation*

## Clone the Git Repository

```bash
~ git clone https://github.com/aws-samples/jenkins-cloudformation-deployment-example.git
```

## Create AWS ECR Repository

Create an AWS ECR Repository for the Jenkins Manager and Jenkins Agent by referencing the [ECR repository policy example](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account) that allows permission to push and pull images from the AWS Shared Services account. You must update the [ecr-permission-policy.json](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/docker/ecr-permission-policy.json) key/value with the AWS Account ID before executing commands.

- [Create AWS ECR Repository for Jenkins Manager and Jenkins Agent](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/feature/docker/ECR.md)

## Build Docker Images

Build the custom docker images for the Jenkins Manager and the Jenkins Agent, then push to the images to AWS ECR Repository. You must navigate to the `docker/` directory, then execute the command according to the required parameters with the AWS account ID, repository name, region, and the build folder name `jenkins-manager/` or `jenkins-agent/` that resides in the current docker directory. The custom docker images will contain a set of starter package installations.

- [Build and push the Jenkins Manager and Jenkins Agent docker images to the AWS ECR Repository](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/feature/docker/BUILDIMAGE.md)

## Deploy Jenkins Application

- After you've built both images, navigate to the `k8s/` directory, modify the manifest file for the jenkins image, then execute the Jenkins [manifest.yaml](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/k8s/manifest.yaml) template to setup the Jenkins application. *(Note: This Jenkins application is not configured with a persistent volume storage, therefore you will need to establish and configure this template to fit that requirement).*

```bash
# Update kubeconfig and set the context of the cluster
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

- The [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/) and [CloudBees AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/) should be installed as part of the Jenkins image build from the Managed Plugins.

![Image: img/jenkins-00.png](img/jenkins-00.png)
*Figure 3. Jenkins Login Page*

- Navigate: Manage Jenkins → Configure Global Security
- Set the Crumb Issuer to remove the error pages to prevent Cross Site Request Forgery exploits.

![Image: img/jenkins-01.png](img/jenkins-01.png)
*Figure 4. Configure Global Security*

## Configure Jenkins Kubernetes Cloud

- Navigate: Manage Jenkins → Manage Nodes and Clouds → Configure Clouds
- Click: Add a new cloud → select Kubernetes from the drop menus

![Image: img/jenkins-02.png](img/jenkins-02.png)

*Figure 5a. Jenkins Configure Nodes & Clouds*

*Note: Before proceeding, please ensure that you have access to your Amazon EKS cluster information, whether it is through Console or CLI.*

- Enter a Name in the field of the Kubernetes Cloud configuration.
- Enter the Kubernetes URL which can be found via AWS Console by navigating to the Amazon EKS service and locating the API server endpoint of the cluster or run the command `kubectl cluster-info`.
- Enter the namespace that will be used in the Kubernetes Namespace field. This will determine where the dynamic kubernetes pods will spawn. In our case, the name of the namespace is `jenkins`.
- During the initial setup of Jenkins Manager on kubernetes, there is an environment variable `JENKINS_URL` which automatically uses the Load Balancer URL to resolve requests. However, we will resolve our requests locally to the cluster IP address.
  - The format is done as the following: [`https://<service-name>.<namespace>.svc.cluster.local`](https://(service-name).(namespace).svc.cluster.local/)

![Image: img/k8s-plugin-01.png](img/k8s-plugin-01.png)
*Figure 5b. Configure Kubernetes Cloud*

## Set AWS Credentials

- You must have the AWS Credentials Binding Plugin installed for before this step. Enter the unique ID name as shown in the example below.
- Enter the IAM Role ARN you created earlier for both the ID and IAM Role to use in the field as shown below.

![Image: img/jenkins-03.png](img/jenkins-03.png)
*Figure 6. AWS Credentials Binding*

![Image: img/jenkins-04.png](img/jenkins-04.png)
*Figure 7. Managed Credentials*

## Create a pipeline

- Navigate to the Jenkins main menu and select new item
- Create a Pipeline

![Image: img/jenkins-05.png](img/jenkins-05.png)
*Figure 8. Create a Pipeline*

## Configure Jenkins Agent

- Setup a Kubernetes YAML template. In this example, we will be using the [k8sPodTemplate.yaml](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/k8s/k8sPodTemplate.yaml) file stored in the `k8s/` folder.
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

## CloudFormation Execution Scripts

- In the deploy, create-changeset, and execute-changeset stages of this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile) pipeline, the [deploy-stack.sh](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/scripts/deploy-stack.sh) is executed and accepts four different parameters. The first parameter set is the stack name. The second parameter is the name of the parameters file name which resides in the `parameters/` folder. The third parameter is the name of the template which reside in the `cloudformation/` folder. The fourth parameter is the boolean condition to decide whether to execute the deployment right away or create a changeset. The fifth parameter is the region of the target account where the stack should be deployed.

```bash
# Deploy a Stack or Execute a Changeset
~ scripts/deploy-stack.sh ${STACK_NAME} ${PARAMETERS_FILE_NAME} ${TEMPLATE_NAME} ${CHANGESET_MODE} ${REGION}
```

- In the delete stage of this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile) pipeline, the [delete-stack.sh](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/scripts/delete-stack.sh) executed and accepts the name and region of the stack that was created to delete the stack.

```bash
# Delete a CloudFormation Stack
~ scripts/delete-stack.sh ${STACK_NAME} ${REGION}
```

## Jenkinsfile

- In this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile), the individual pipeline build jobs will deploy individual microservices. The `k8sPodTemplate.yaml` is used to specify the kubernetes pod details and the inbound-agent that will be used to run the pipeline.
- This pipeline stage will consist of the several stages for stack deployment, create changeset, execute changeset, and stack deletion. The `deploy-stack.sh` will execute when selected via parameters, and likewise the `delete-stack.sh` will be executed when selected by the parameters.
- If you observe closely, there are several variables used within the pipeline stage actions below
  - `CHANGESET_MODE = True`, this will proceed to deploy a stack or execute changeset.
  - `CHANGESET_MODE = False`, this will only create a changeset without executing the changes.
  - `STACK_NAME = example-stack`, In this example the name of the stack is called *example-stack*.
  - `PARAMETERS_FILE_NAME = example-stack-parameters.properties`, this will pass the parameter values into the stack, the format of the file name follows `<parameter-file-name>.properties`. In our case we are using `example-stack-parameters.properties` under the `parameters/` folder.
  - `TEMPLATE_NAME = S3-Bucket.yaml`, The name of this variable is equivalent to the format `<template-name>.yaml`. In this example the template name is called `S3-Bucket.yaml`, under the `cloudformation/` folder.
  - `CFN_CREDENTIALS_ID = arn:aws:iam::role/AWSCloudFormationStackExecutionRole`, This is the Unique ID that references the IAM Role ARN which is the account we will assume role using the [AmazonWebServicesCredentialsBinding](https://www.jenkins.io/doc/pipeline/steps/credentials-binding/) to perform our deployment based on the selected choice parameterized pipeline.
  - `REGION = us-east-1`, Enter the region you're using for the target account.
  - `TOGGLE = true`, If you do not set the toggle flag to true before executing the build action, it will automatically abort the pipeline for any action. This is to prevent accidental build execution changes from taking place without confirmation.

## Jenkins Pipeline: Execute a pipeline

- Click Build with Parameters then select a build action.

![Image: img/jenkins-06.png](img/jenkins-06.png)
*Figure 9a. Build with Parameters*

- You can examine the pipeline stages a bit further for the choice you selected. You can view more details of the stages below and verify in your AWS account that the CloudFormation stack was executed.

![Image: img/jenkins-07.png](img/jenkins-07.png)
*Figure 9b. Pipeline Stage View*

- The Final Step is to execute your pipeline and watch the pods spin up dynamically in your terminal. As you can see below the jenkins agent pod spawned then terminated after the work was completed. You can watch this task on your own by executing the following command:

```bash
# Watch the pods spawn in the "jenkins" namespace
~ kubectl get pods -n jenkins -w
```

![Image: img/jenkins-08.png](img/jenkins-08.png)
*Figure 10. Watch Jenkins Agent Pods Spawn*

## Security Considerations

This blog provides a high level overview of the best practices for cross-account deployment and maintaining the isolation between the applications. We evaluated the cross-account application deployment permissions and will describe the current state and what you should avoid. As part of the security best practice we will maintain isolation among multiple apps that are deployed in these environments. eg. Pipeline 1 does not deploy to the infrastructure belonging to Pipeline 2.

### Best Practice - *Current State*

We implemented the use of cross-account roles that can restrict unauthorized access across build jobs. Behind this approach, we will utilize the concept of assume-role that will enable the requesting role to obtain temporary credentials (from STS service) of the target role and execute actions permitted by the target
role. This is a safer approach than using hard-coded credentials. The requesting role could be either the inherited EC2 instance role OR specific user credentials, but in our case we are using the inherited EC2 instance role.

For ease of understanding, we will refer the target-role as execution-role below.

![Image: img/current-state.png](img/current-state.png)
*Figure 11. Current State*

#### *Step 1*

As per the security best practice of assigning minimum privileges, it is required to first create execution role in IAM in the target account that has deployment permissions (either via CloudFormation OR via CLI’s). eg. app-dev-role in Dev account and app-prod-role in Prod account.

#### *Step 2*

For each of those roles, we configure a trust relationship with the parent account ID (Shared Services account). This will enable any roles in the Shared Services account (with assume-role permission) to assume the role of the execution role and deploy it on respective hosting infrastructure. eg. app-dev-role in Dev account will be a common execution role that will deploy various apps across infrastructure.

#### *Step 3*

Then we create a local role in the Shared Services account and configure credentials within Jenkins to be utilized by the Build Jobs. Provide the job with the assume-role permissions and specify the list of ARN’s across all the accounts. Alternatively, the inherited EC2 instance role can also be utilized to assume the role of execution-role.

### Further Isolation - *Security Hardening*

This approach implements guard-rails to enforce the application isolation in an account. However, if using CloudFormation, the security violation risk is low (due to the automation) and configuration overhead is high.

![Image: img/solution-02.png](img/solution-02.png)
*Figure 12. Security Hardening*

#### *Step 1*

As per the security best practice of assigning minimum privileges, it is required to first create execution roles in IAM in the target account for each application hosting infrastructure. Thus we create app1-dev-role and app2-dev-role in the Dev account and restrict those roles to access only respective hosting infrastructure. Similarly, we create app1-prod-role and app2-prod-role in Prod account and restrict each of them to their respective hosting infrastructure.

#### *Step 2*

For each of those roles, we configure trust relationship with the parent account ID (Shared Services account). This time, we will add a condition to check for the external ID. This will enable specific roles using the same external ID in the Shared account (with assume-role permission) to assume the role of the execution role and deploy it on respective hosting infrastructure.

#### *Step 3*

Then we create a local user in the Shared account and configure credentials within Jenkins to be utilized by the Build Jobs. Provide the job with the assume-role permissions and specify the list of ARN’s across all the accounts. The AWS CLI that will execute the deployment would be hard-coded with the external ID to ensure that it assumes the correct execution-role to carry out deployment.

You may also adopt a tag-based approach (ABAC), by consistently tagging every resource with identity to differentiate across applications and utilizing policy conditions to enforce the permissions.

### *Requirement*

As per our understanding, there is a Jenkins manager that is running as a container in an EC2 compute instance which resides within a Shared AWS account. This Jenkins application represents individual pipelines deploying unique microservices that build & deploy to multiple environments in separate AWS accounts. The cross-account deployment uses the admin credentials of the target AWS account to do the deployment.

With this methodology, it is not a good practice to share the account credentials externally. Additionally, there is a need to eliminate the risk of the deployment errors and maintain application isolation within the same account.

Note that the deployment steps are being run using aws cli’s and thus our solution will be focused around usage of aws cli.

The risk is much lower when using CloudFormation / CDK to carry out deployments because the aws CLI’s executed from the build jobs will specify stack names as parametrized inputs and very low probability of stack-name error. However, it is still not a good practice to use admin credentials, that too of the target account.

## Code Repository

- [Amazon EKS Jenkins Integration](https://github.com/aws-samples/jenkins-cloudformation-deployment-example.git)

## References

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [CloudBees AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/)

## Conclusion

This post guided you through the process of building out Amazon EKS and integrating Jenkins to orchestrate workloads. We demonstrated how you can use this to deploy securely in multiple accounts with dynamic Jenkins agents and create alignment to your business with similar use cases. To learn more about Amazon EKS, head over to our [documentation](https://aws.amazon.com/eks/getting-started/) pages or explore our [console](https://console.aws.amazon.com/eks/home?region=us-east-1#).
