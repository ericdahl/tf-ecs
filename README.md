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


# Notes

## Investigation on task startup time limit with ALB

12 Tasks with `DELAY_START_CONNECT=30`, deploying new task, observing task deployment

interval/healthy/unhealthy (30s startup time)
1. 10/10/10 - clean deploy
2. 10/10/10 - clean (redeploy)
3. 10/10/2 -20:45:18 -  
    - **all unhealthy, then 2 unhealthy for 10m+,  not stable**
4. 10/10/10 - clean
5. 10/2/10 - clean 
6. 10/2/10 - clean
7. 10/10/2 - 21:13:05 
    1. 2/12 Request timed out, 10 Health checks failed
    2. 12/12 Health checks failed
    3. 12/12 Health checks failed
    4. 12/12 Health checks failed
    5. 12/12 Health checks failed

### Questions

- How is it possible for a 30s startup task to have any tasks stabilize if using 10s interval and 
unhealthy_threshold=2? 10/12 were healthy immediately but other 2 failed repeatedly

- Why is it sometimes Request timed out and sometimes Health checks failed?
