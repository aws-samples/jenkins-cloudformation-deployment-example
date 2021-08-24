# Jenkins Pipeline Contents

## CloudFormation Execution Scripts

This [deploy-stack.sh](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/scripts/deploy-stack.sh) file can accept four different parameters and conduct several types of CloudFormation stack executions such as deploy, create-changeset, and execute-changeset. This is also reflected in the stages of this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile) pipeline. As for the [delete-stack.sh](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/scripts/delete-stack.sh) file, two parameters are accepted, and, when executed, it will delete a CloudFormation stack based on the given stack name and region.

- The first parameter set is the stack name. The second parameter is the name of the parameters file name which resides in the `parameters/` folder. The third parameter is the name of the template which reside in the `cloudformation/` folder. The fourth parameter is the boolean condition to decide whether to execute the deployment right away or create a changeset. The fifth parameter is the region of the target account where the stack should be deployed.

```bash
# Deploy a Stack or Execute a Changeset
~ scripts/deploy-stack.sh ${STACK_NAME} ${PARAMETERS_FILE_NAME} ${TEMPLATE_NAME} ${CHANGESET_MODE} ${REGION}
```

- In the delete stage of this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile) pipeline, the [delete-stack.sh](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/scripts/delete-stack.sh) executed and accepts the name and region of the stack that was created to delete the stack.

```bash
# Delete a CloudFormation Stack
~ scripts/delete-stack.sh ${STACK_NAME} ${REGION}
```

---

## Jenkinsfile

In this [Jenkinsfile](https://github.com/aws-samples/jenkins-cloudformation-deployment-example/blob/main/Jenkinsfile), the individual pipeline build jobs will deploy individual microservices. The `k8sPodTemplate.yaml` is utilized to specify the kubernetes pod details and the inbound-agent that will be utilized to run the pipeline.

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
