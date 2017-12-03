# tf-ecs

Terraform AWS ECS modules

The `tf` files in the root of the repo launch a test cluster

## ecs_cluster

Cluster-wide resources like

- ECS Cluster
- IAM roles for cluster
- AMI selection

## ecs_asg

AutoScaling Group to add to cluster

## ecs_drainer

Lambda to drain container instances on ASG scale-in events
