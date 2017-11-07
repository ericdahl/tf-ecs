from __future__ import print_function
import boto3
import json
import time
import logging
import os

# seconds to wait in between checks to determine whether it's safe to terminate the instance
SLEEP_TIME = 30

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lookup_container_instance_id(ecs, cluster_name, ec2_instance_id):
    """
    Lookup the ECS Container Instance for the EC2 instance and cluster.

    :param ecs: boto service object
    :param cluster_name: name of the ECS cluster to search
    :param ec2_instance_id: EC2 instance id in ECS cluster
    :return: the full "described" container instance object
    """

    # Yet again, AWS doesn't provide a good API for common functionality like identifying the Container Instance from
    # the EC2 instance, so we have to iterate over all container instances in the cluster to search for it.
    paginator = ecs.get_paginator('list_container_instances')
    for page in paginator.paginate(cluster=cluster_name):
        cinstances = page['containerInstanceArns']

        for cinstance in ecs.describe_container_instances(cluster=cluster_name,
                                                          containerInstances=cinstances)['containerInstances']:
            cinstance_arn = cinstance['containerInstanceArn']
            logger.debug("Examining container instance [%s]", cinstance_arn)
            if cinstance['ec2InstanceId'] == ec2_instance_id:
                logger.info("Found container instance [%s] for instance id [%s]", cinstance_arn, ec2_instance_id)
                return cinstance

    raise ValueError("Unable to find container instance for EC2 instance id [{}]".format(ec2_instance_id))


def drain_cinstance(ecs, cluster_name, cinstance):
    """
    Mark a container instance as DRAINING if not already set

    :param ecs: boto service object
    :param cluster_name:  name of the ECS cluster
    :param cinstance:  "described" container instance object
    :return:
    """

    cinstance_arn = cinstance['containerInstanceArn']
    ec2_instance_id = cinstance['ec2InstanceId']

    if cinstance['status'] != 'DRAINING':
        logger.info("Updating state to DRAINING for cluster [%s] cinstance [%s] (ec2 instance [%s])",
                    cluster_name, cinstance_arn, ec2_instance_id)
        response = ecs.update_container_instances_state(cluster=cluster_name,
                                                        containerInstances=[cinstance_arn],
                                                        status='DRAINING')
        logger.info("Drain response: [%s]", response)

    else:
        logger.info("Instance already in DRAINING for cluster [%s] cinstance [%s] (ec2 instance [%s])",
                    cluster_name, cinstance_arn, ec2_instance_id)


def load_cinstance(ecs, cluster_name, cinstance_arn):
    """
    Load (or reload) a "described" container instance object from it's ARN.
    """
    response = ecs.describe_container_instances(cluster=cluster_name, containerInstances=[cinstance_arn])

    return response['containerInstances'][0]


def lambda_handler(event, context):
    """
    Entry point for lambda execution

    :param event: Lambda event (SNS message)
    :param context: Lambda context
    :return: nothing
    """

    logger.info("Lambda received the event %s", json.dumps(event))

    message = json.loads(event['Records'][0]['Sns']['Message'])
    logger.info("Lambda received the event message %s", json.dumps(message))

    if 'LifecycleTransition' in message and message["LifecycleTransition"] == "autoscaling:EC2_INSTANCE_TERMINATING":
        ec2_instance_id = message['EC2InstanceId']

        session = boto3.session.Session()

        ecs = session.client('ecs')
        """:type : pyboto3.ecs """

        cluster_name = os.environ['CLUSTER_NAME']
        cinstance = lookup_container_instance_id(ecs, cluster_name, ec2_instance_id)

        drain_cinstance(ecs, cluster_name, cinstance)

        while True:

            cinstance_arn = cinstance['containerInstanceArn']
            running_tasks = cinstance['runningTasksCount']

            logger.info("Container instance [%s] (%s) has [%s] running tasks", cinstance_arn, ec2_instance_id, running_tasks)
            if running_tasks == 0:
                logger.info("OK to terminate [%s]. Completing lifecycle action.", ec2_instance_id)

                asg = session.client('autoscaling')
                """:type : pyboto3.autoscaling """

                response = asg.complete_lifecycle_action(
                    LifecycleHookName=message['LifecycleHookName'],
                    AutoScalingGroupName=message['AutoScalingGroupName'],
                    LifecycleActionResult='CONTINUE',
                    InstanceId=ec2_instance_id)
                logger.info("Response from complete_lifecycle_action %s", response)

                # done with lambda
                return

            else:
                # After we set the instance to DRAINING, we need to allow some time for tasks to be spun up on other
                # hosts, report healthy, and for the old tasks then need to deregister/drain out of the ALB and stop.
                # This could take a couple minutes for a graceful transition.
                #
                # We're simply sleeping here to give time for this to occur before retrying it via another lambda
                # invocation. There's probably a more elegant (complicated) solution but this is simple and we just
                # incur the cost of an extra penny for every 100 30s lambda calls.
                logger.info("Sleeping for [%s] seconds to allow tasks to finish", SLEEP_TIME)
                time.sleep(SLEEP_TIME)

                if 'attempts' not in message:
                    message['attempts'] = 0

                message['attempts'] += 1

                if message['attempts'] > 5:
                    logger.warn("Tasks still running on [%s] after [%s] attempts. Lambda has [%s] ms remaining.",
                                ec2_instance_id, message['attempts'], context.get_remaining_time_in_millis())

                # reload container instance description to get updated status of running tasks
                cinstance = load_cinstance(ecs, cluster_name, cinstance['containerInstanceArn'])

                # Lambdas time-out after 5 minutes, but we might want to configure the lifecycle hook timeout to
                # be larger for tasks which take some time to deregister, so we re-trigger the lambda by sending
                # the same SNS message back to the topic if we're running out of time
                if context.get_remaining_time_in_millis() < (SLEEP_TIME + 5) * 1000:
                    logger.info("Lambda has run out of time, re-sending SNS message to resume in a different lambda")

                    sns = session.client('sns')
                    """:type : pyboto3.sns """

                    sns_response = sns.publish(
                        TopicArn=event['Records'][0]['Sns']['TopicArn'],
                        Message=json.dumps(message),
                        Subject='Publishing SNS message to invoke lambda again..'
                    )
                    logger.info("SNS response: %s", sns_response)
                    return
