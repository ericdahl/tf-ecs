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

## Unhealthy tasks without failed health check

An ALB Target can go unhealthy due to user traffic even if the health check itself is responsive

maybe? difficult to reproduce

### Questions

- How is it possible for a 30s startup task to have any tasks stabilize if using 10s interval and 
unhealthy_threshold=2? 10/12 were healthy immediately but other 2 failed repeatedly

- Why is it sometimes Request timed out and sometimes Health checks failed?


# ECS Capacity Provider

![Design of ECS Capacity Providers](https://user-images.githubusercontent.com/4712580/140661839-f1d34c36-3719-44d4-9d09-de65c1e01bde.png)


# 2021-11-07 ECS Optimized AMI notes

```
$ docker info
...
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Native Overlay Diff: true
  userxattr: false

```

- container data in  /var/lib/docker/overlay2/

```
]# uname -a
Linux ip-10-0-101-211.ec2.internal 4.14.248-189.473.amzn2.x86_64 #1 SMP Mon Sep 27 05:52:26 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```
