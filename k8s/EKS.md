# Create EKS Cluster

Verify that your AWS configuration is pointing to the correct region you want EKS deployed. If you do not specify the region, the AWS Profile you setup earlier will be used as the default for where the cluster will reside. The following parameters is an example which will vary based on your preference. If you choose to deploy with a different name, region, zone, or node capacity please modify accordingly.

```bash
# Create the EKS Cluster
~ eksctl create cluster \
> --name <CLUSTER-NAME> \
> --region <REGION> \
> --with-oidc \
> --zones "<AVAILABILITY-ZONE-1>,<AVAILABILITY-ZONE-2>" \
> --nodegroup-name <NODEGROUP-NAME> \
> --nodes-min 2 \
> --nodes-max 4 \
> --enable-ssm \
> --managed \
> --asg-access
```

```bash
# Verify that EKS nodes are up running
~ kubectl get nodes
```
