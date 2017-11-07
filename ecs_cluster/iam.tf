resource "aws_iam_role" "ec2_role" {
  name = "tf-ecs-example-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "default" {
  name       = "${var.cluster_name}-ec2"
  roles      = ["${aws_iam_role.ec2_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.cluster_name}-instance-profile"
  role = "${aws_iam_role.ec2_role.name}"
}

resource "aws_iam_role" "ecs_service" {
  name = "tf-ecs-example-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecs_service" {
  name       = "${var.cluster_name}-ecs-service"
  roles      = ["${aws_iam_role.ecs_service.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

//resource "aws_iam_role_policy" "test_policy" {
//  name = "test_policy"
//  role = "${aws_iam_role.asg_lambda.id}"
//
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": [
//          "autoscaling:CompleteLifecycleAction",
//          "logs:CreateLogGroup",
//          "logs:CreateLogStream",
//          "logs:PutLogEvents",
//          "ec2:DescribeInstances",
//          "ec2:DescribeInstanceAttribute",
//          "ec2:DescribeInstanceStatus",
//          "ec2:DescribeHosts",
//          "ecs:ListContainerInstances",
//          "ecs:SubmitContainerStateChange",
//          "ecs:SubmitTaskStateChange",
//          "ecs:DescribeContainerInstances",
//          "ecs:UpdateContainerInstancesState",
//          "ecs:ListTasks",
//          "ecs:DescribeTasks"
//      ],
//      "Effect": "Allow",
//      "Resource": "*"
//    },
//    {
//      "Action": [
//          "sns:Publish"
//      ],
//      "Effect": "Allow",
//      "Resource": "arn:aws:sns:*:*:*asg-drainer"
//    }
//  ]
//}
//EOF
//}


//resource "aws_iam_role" "asg_lambda" {
//  name = "asg_lambda"
//
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": "sts:AssumeRole",
//      "Principal": {
//        "Service": "lambda.amazonaws.com"
//      },
//      "Effect": "Allow",
//      "Sid": ""
//    }
//  ]
//}
//EOF
//}
//
//
//
//resource "aws_iam_role_policy_attachment" "default" {
//  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
//  role = "${aws_iam_role.asg_lambda.name}"
//}


//resource "aws_iam_role_policy" "asg_hook_policy" {
//  name = "test_policy"
//  role = "${aws_iam_role.asg_hook.id}"
//
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": [
//          "sns:Publish"
//      ],
//      "Effect": "Allow",
//      "Resource": "arn:aws:sns:*:*:*asg-drainer"
//    }
//  ]
//}
//EOF
//}
