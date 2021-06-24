# **Orchestrate Jenkins Workloads using Dynamic Pod Autoscaling with Amazon EKS**

In this blog post, we’ll demonstrate how to leverage [Jenkins](https://www.jenkins.io/) with [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) by running a Jenkins Manager within an EKS pod. By doing so, we can run Jenkins workloads by allowing Amazon EKS to spawn dynamic Jenkins Agent(s) to perform application and infrastructure deployment. Traditionally, customers will setup a Jenkins Manager-Agent architecture which will contain a set of manually added nodes with no autoscaling capabilities. By implementing this strategy, a robust approach is carried out to optimize the best performance with right sized compute capacity and work needed to successfully perform the build tasks.

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

## Prerequisite(s)

The following below is the minimum requirement in order to ensure this solution will work.

- Account Prerequisite(s)
  - Shared Services Account: This is where the Amazon EKS Cluster will reside.
  - Target Account: This is destination of the CI/CD pipeline deployments.

- Build Requirement(s)
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
  - [Docker CLI](https://docs.docker.com/get-docker/) - *Note: The docker engine must be running to build images.*
  - [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
  - [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
  - [eksctl](https://github.com/weaveworks/eksctl)

- Configure your [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) with the associated region.

- Verify if the build requirements were installed correctly by checking the version.

- [Create an EKS Cluster using eksctl.](EKS.md)

- Verify that EKS nodes are up running and available.

- [Create an AWS ECR Repository for the Jenkins Manager and Jenkins Agent.](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account)

## Clone the Git Repository

```bash
~ git clone https://github.com/aws-samples/jenkins-cloudformation-deployment-example.git
```

## Security Considerations

This blog provides a high level overview of the best practices for cross-account deployment and maintaining the isolation between the applications. We evaluated the cross-account application deployment permissions and will describe the current state and what you should avoid. As part of the security best practice we will maintain isolation among multiple apps that are deployed in these environments. eg. Pipeline 1 does not deploy to the infrastructure belonging to Pipeline 2.

### Requirement

As per our understanding, there is a Jenkins manager that is running as a container in an EC2 compute instance which resides within a Shared AWS account. This Jenkins application represents individual pipelines deploying unique microservices that build & deploy to multiple environments in separate AWS accounts. The cross-account deployment uses the admin credentials of the target AWS account to do the deployment.

With this methodology, it is not a good practice to share the account credentials externally. Additionally, there is a need to eliminate the risk of the deployment errors and maintain application isolation within the same account.

Note that the deployment steps are being run using aws cli’s and thus our solution will be focused around usage of aws cli.

The risk is much lower when using CloudFormation / CDK to carry out deployments because the aws CLI’s executed from the build jobs will specify stack names as parametrized inputs and very low probability of stack-name error. However, it is still not a good practice to use admin credentials, that too of the target account.

### Best Practice - *Current Approach*

We implemented the use of cross-account roles that can restrict unauthorized access across build jobs. Behind this approach, we will utilize the concept of assume-role that will enable the requesting role to obtain temporary credentials (from STS service) of the target role and execute actions permitted by the target
role. This is a safer approach than using hard-coded credentials. The requesting role could be either the inherited EC2 instance role OR specific user credentials, but in our case we are using the inherited EC2 instance role.

For ease of understanding, we will refer the target-role as execution-role below.

![Image: img/current-state.png](img/current-state.png)
*Figure 2. Current Approach*

- As per the security best practice of assigning minimum privileges, it is required to first create execution role in IAM in the target account that has deployment permissions (either via CloudFormation OR via CLI’s). eg. app-dev-role in Dev account and app-prod-role in Prod account.

- For each of those roles, we configure a trust relationship with the parent account ID (Shared Services account). This will enable any roles in the Shared Services account (with assume-role permission) to assume the role of the execution role and deploy it on respective hosting infrastructure. eg. app-dev-role in Dev account will be a common execution role that will deploy various apps across infrastructure.

- Then we create a local role in the Shared Services account and configure credentials within Jenkins to be utilized by the Build Jobs. Provide the job with the assume-role permissions and specify the list of ARN’s across all the accounts. Alternatively, the inherited EC2 instance role can also be utilized to assume the role of execution-role.

### Create Cross-Account IAM Roles

[Cross-account IAM roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html#tutorial_cross-account-with-roles-prereqs) allow users to securely access AWS resources in a target account, while maintaining observability of that AWS account. The cross-account IAM role includes a trust policy that allows AWS identities in another AWS account to assume the given role. This allows me the ability to create a role in one AWS account that delegates specific permissions to another AWS account.

- Create an IAM role that has a common name in each target account. The role name we've created for use is called `AWSCloudFormationStackExecutionRole`. The role must have permissions to perform CloudFormation actions and any actions pertaining to the resources that will be created. In our case, we will be creating and S3 Bucket using CloudFormation.
- This IAM role must also have an established trust relationship to the Shared Services account. In this case, the Jenkins Agent will be granted the ability to assume the role of the particular target account from the Shared Services account.
- In our case, the IAM entity that will assume the `AWSCloudFormationStackExecutionRole` is the EKS Node Instance Role that is associated to the EKS Cluster Nodes.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateUploadBucket",
                "cloudformation:ListStacks",
                "cloudformation:CancelUpdateStack",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:ListChangeSets",
                "cloudformation:ListStackResources",
                "cloudformation:DescribeStackResources",
                "cloudformation:DescribeStackResource",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeStacks",
                "cloudformation:ContinueUpdateRollback",
                "cloudformation:DescribeStackEvents",
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:UpdateStack",
                "cloudformation:DescribeChangeSet",
                "s3:PutBucketPublicAccessBlock",
                "s3:CreateBucket",
                "s3:DeleteBucketPolicy",
                "s3:PutEncryptionConfiguration",
                "s3:PutBucketPolicy",
                "s3:DeleteBucket"
            ],
            "Resource": "*"
        }
    ]
}
```

## Build Docker Images

Build the custom docker images for the Jenkins Manager and the Jenkins Agent, then push to the images to AWS ECR Repository. You must navigate to the `docker/` directory, then execute the command according to the required parameters with the AWS account ID, repository name, region, and the build folder name `jenkins-manager/` or `jenkins-agent/` that resides in the current docker directory. The custom docker images will contain a set of starter package installations.

- [Build and push the Jenkins Manager and Jenkins Agent docker images to the AWS ECR Repository](BUILDIMAGE.md)

## Deploy Jenkins Application

After you've built both images, navigate to the `k8s/` directory, modify the manifest file for the jenkins image, then execute the Jenkins [manifest.yaml](k8s/manifest.yaml) template to setup the Jenkins application. *(Note: This Jenkins application is not configured with a persistent volume storage, therefore you will need to establish and configure this template to fit that requirement).*

- [Deploy the Jenkins Application to the EKS Cluster](MANAGER.md)

```bash
# Fetch the Application URL or navigate to the AWS Console for the Load Balancer
~ kubectl get svc -n jenkins

# Verify that jenkins deployment/pods are up running
~ kubectl get pods -n jenkins

# Replace with jenkins manager pod name and fetch Jenkins login password
~ kubectl exec -it pod/<JENKINS-MANAGER-POD-NAME> -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

- The [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/) and [CloudBees AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/) should be installed as part of the Jenkins image build from the Managed Plugins.

- Navigate: Manage Jenkins → Configure Global Security
- Set the Crumb Issuer to remove the error pages to prevent Cross Site Request Forgery exploits.

![Image: img/jenkins-01.png](img/jenkins-01.png)
*Figure 3. Configure Global Security*

## Configure Jenkins Kubernetes Cloud

- Navigate: Manage Jenkins → Manage Nodes and Clouds → Configure Clouds
- Click: Add a new cloud → select Kubernetes from the drop menus

![Image: img/jenkins-02.png](img/jenkins-02.png)

*Figure 4a. Jenkins Configure Nodes & Clouds*

*Note: Before proceeding, please ensure that you have access to your Amazon EKS cluster information, whether it is through Console or CLI.*

- Enter a Name in the field of the Kubernetes Cloud configuration.
- Enter the Kubernetes URL which can be found via AWS Console by navigating to the Amazon EKS service and locating the API server endpoint of the cluster or run the command `kubectl cluster-info`.
- Enter the namespace that will be used in the Kubernetes Namespace field. This will determine where the dynamic kubernetes pods will spawn. In our case, the name of the namespace is `jenkins`.
- During the initial setup of Jenkins Manager on kubernetes, there is an environment variable `JENKINS_URL` which automatically uses the Load Balancer URL to resolve requests. However, we will resolve our requests locally to the cluster IP address.
  - The format is done as the following: [`https://<service-name>.<namespace>.svc.cluster.local`](https://(service-name).(namespace).svc.cluster.local/)

![Image: img/k8s-plugin-01.png](img/k8s-plugin-01-a.png)
![Image: img/k8s-plugin-01.png](img/k8s-plugin-01-b.png)
*Figure 4b. Configure Kubernetes Cloud*

## Set AWS Credentials

One of the key reason we're using an IAM role instead of access keys is due to security concerns. For any given approach that involves IAM, it is the best practice to use temporary credentials.

- You must have the AWS Credentials Binding Plugin installed for before this step. Enter the unique ID name as shown in the example below.
- Enter the IAM Role ARN you created earlier for both the ID and IAM Role to use in the field as shown below.

![Image: img/jenkins-03.png](img/jenkins-03.png)
*Figure 5. AWS Credentials Binding*

![Image: img/jenkins-04.png](img/jenkins-04.png)
*Figure 6. Managed Credentials*

## Create a pipeline

- Navigate to the Jenkins main menu and select new item
- Create a Pipeline

![Image: img/jenkins-05.png](img/jenkins-05.png)
*Figure 7. Create a Pipeline*

## Configure Jenkins Agent

Setup a Kubernetes YAML template after you've built the agent image. In this example, we will be using the [k8sPodTemplate.yaml](k8s/k8sPodTemplate.yaml) file stored in the `k8s/` folder.

- [Configure Jenkins Agent k8s Pod Template](AGENT.md)

## CloudFormation Execution Scripts

This [deploy-stack.sh](scripts/deploy-stack.sh) file can accept four different parameters and perform several types of CloudFormation stack executions such as deploy, create-changeset, and execute-changeset which is also reflected in the stages of this [Jenkinsfile](Jenkinsfile) pipeline. As for the [delete-stack.sh](scripts/delete-stack.sh) file, two parameters are accepted and when executed it will delete a CloudFormation stack based on the given stack name and region.

- [Understanding Pipeline Execution Scripts for CloudFormation](JENKINS.md)

## Jenkinsfile

In this [Jenkinsfile](Jenkinsfile), the individual pipeline build jobs will deploy individual microservices. The `k8sPodTemplate.yaml` is used to specify the kubernetes pod details and the inbound-agent that will be used to run the pipeline.

- [Jenkinsfile Parameterized Pipeline Configurations](JENKINS.md)

## Jenkins Pipeline: Execute a pipeline

- Click Build with Parameters then select a build action.

![Image: img/jenkins-06.png](img/jenkins-06.png)
*Figure 8a. Build with Parameters*

- You can examine the pipeline stages a bit further for the choice you selected. You can view more details of the stages below and verify in your AWS account that the CloudFormation stack was executed.

![Image: img/jenkins-07.png](img/jenkins-07.png)
*Figure 8b. Pipeline Stage View*

- The Final Step is to execute your pipeline and watch the pods spin up dynamically in your terminal. As you can see below the jenkins agent pod spawned then terminated after the work was completed. You can watch this task on your own by executing the following command:

```bash
# Watch the pods spawn in the "jenkins" namespace
~ kubectl get pods -n jenkins -w
```

![Image: img/jenkins-08.png](img/jenkins-08.png)
*Figure 9. Watch Jenkins Agent Pods Spawn*

## Code Repository

- [Amazon EKS Jenkins Integration](https://github.com/aws-samples/jenkins-cloudformation-deployment-example.git)

## References

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [CloudBees AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/)

## Conclusion

This post guided you through the process of building out Amazon EKS and integrating Jenkins to orchestrate workloads. We demonstrated how you can use this to deploy securely in multiple accounts with dynamic Jenkins agents and create alignment to your business with similar use cases. To learn more about Amazon EKS, head over to our [documentation](https://aws.amazon.com/eks/getting-started/) pages or explore our [console](https://console.aws.amazon.com/eks/home?region=us-east-1#).
