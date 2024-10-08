# tf-ecs

ECS Example with Terraform

This creates a EC2-based ECS Cluster using a Capacity Provider. For an even simpler Fargate (serverless)
example, see <https://github.com/ericdahl/hello-ecs>. EC2 can be helpful in some situations, particularly
when debugging and understanding how ECS works (e.g., via monitoring logs, docker commands, etc)

This has various demo services that can be
toggled on via variables. You can enable them with a `terraform.tfvars` file like:

```
enable_ec2_httpbin = true
```

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


- Fargate
  - enables split of spot/on-demand
  - before: was mostly either on-demand or spot
  - do this via setting base/weight on both the on-demand/spot capacity providers at once

- Enables tasks to be in "Provisioning" state, after Pending, which kicks off capacity provider
- CloudWatch auto-generated alarms
  - scale-out after 1 min (normal target tracking is 3 min?)
  - scale-in after 15 min
- can support multiple instance types

##  Managed Scaling vs Managed Instance Protection

### Managed Scaling
- causes ECS to manage scale-in and scale-out
- creates the Target Tracking autoscaling policy
  - targetCapacity is used for TargetTracking
- if disabled, what's the point of Capacity Provider?

#### Test

- 2 hosts - t2.medium (2 cpu, 4 GB)
- 10 httpbin tasks - 256 cpu_shares - spread(az), spread(instance)
- result 0: 
  - even split 5/5 tasks
  - CapacityProviderReservation = 100
- test: deploy httpbin-large requiring 2000 cpu_shares ; 
  - hypothesis - task=provisioning then CapacityProvider 150 then add host then run task
  - result 1
    - **Provisioning is stuck**
      - Task stuck in Provisioning
      - CapacityProviderReservation stays at 100
      - host count stays at 2
      - Even though for M/N calculation, M should be 3
        - 2*2048 - (10 * 256 + 2000) = -464
      - waited ~10 min
- test: update target % 100 -> 90
  - hypothesis: 3rd host launched, provisioning task can run
    - correct
  - result 2
    - CW Alarms updated to:
      - "> 90 for 1 min"
      - < 81 for 15 min
    - 3rd host launched - CapacityProviderReservation stays at 100
    - alarm triggered again
    - 4th host launched
    - CapacityProviderReservation drops to 75 (_below scale-in_)
    - no scale-out/in cycle due to Managed Term Protection?
      - but ASG desired size was 4
- if instance launched but alarm still open, doesn't retrigger scaling policy (stuck)
 
### Managed Termination Protection
- requires Managed Scaling to be enabled
- prevents instances with tasks from beign terminated, via using ASG native "scale in protection"
  - goal is to not disrupt services on a host
- concern: could lead to many hosts with just one task, unbalanced?
- if enabled then disabled, existing instances don't have this removed

## Migration Path

- ECS Services have must have one of the following:
  - Launch Type: EC2/Fargate
  - Capacity Provider Strategy: array of capacity providers
  - Defaults - New Service
    - if ECS Cluster has a Default Capacity Provider Strategy, Service gets CP
    - else: Service uses LT: EC2
  - Existing Service
    - does not get switched to Capacity Provider
    - Possible to switch but requires task recycle

### Tests

- Test 1
  - Cluster with CP; legacy service with LT: EC2 (via old default)
    - ECS redeploy - no change to service
    - ECS deploy with capacity provider set in TF - no change to service
      - bug?
    - ECS deploy after manual change to enable CP - no change
      - TF state file auto-updates to use CP rather than LT
        - ideal logic for migration but special cases here?
- need to test with DAEMONS

### Plan

- Criteria
  - Need to avoid unnecessary Service Recreates to avoid downtime
- Caveats
  - **Can't switch from LT to CP for an ECS Service with TF normally**
    - Plan shows no changes
    - could recreate via taint
- ensure ECS Service module doesn't define launch type or Capacity Provider Strategy
  - to support both cluster types at once
  - default: if cluster has default CP, CP, otherwise EC2 LT
- switch old ECS Service manually from LT to CP
  - tests: when not defined, TF seems fine with this, "no changes". 
    - state updates automatically without issue
    - TODO: special cases here for some TF Services?

## questions
- managed termination protection - would this increase costs due to hosts with just single tasks?
  - should still use lambda drainer for this?
- can normal Target Tracking have 1 minute scale out threshold? is this a secret API?

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
