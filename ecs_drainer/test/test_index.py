from drainer import index
import json
import os
from moto import mock_ecs, mock_ec2, mock_autoscaling
import boto3



@mock_ecs
@mock_ec2
@mock_autoscaling
def test_foo():


    session = boto3.session.Session()

    ecs = session.client('ecs')
    """:type : pyboto3.ecs """

    ec2 = session.client('ec2')
    """:type : pyboto3.ec2 """

    ecs.create_cluster(clusterName='test')

    instance = ec2.run_instances(ImageId="ami-5ec1673e", MinCount=1, MaxCount=1)
    print instance['Instances'][0]['InstanceId']
    instance['Instances'][0]['InstanceId'] = 'i-01fb76f815cbcd1e5'
    print instance['Instances'][0]['InstanceId']


    os.environ['CLUSTER_NAME'] =  'test'

    with open('test/input.json') as json_data:
        d = json.load(json_data)
        index.lambda_handler(d, 0)


    # json.loads()


