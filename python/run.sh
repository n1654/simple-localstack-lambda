#!/usr/bin/bash

# Create the execution role that gives your function permission
# to access AWS resources. To create an execution role with the AWS CLI,
# use the create-role command.
aws iam create-role \
--role-name lambda-ex \
--assume-role-policy-document file://trust-policy.json \
--endpoint-url=http://127.0.0.1:4566

# To add permissions to the role, use the attach-policy-to-role command.
# Start by adding the AWSLambdaBasicExecutionRole managed policy.
# The AWSLambdaBasicExecutionRole policy has the permissions
# that the function needs to write logs to CloudWatch Logs.
aws iam attach-role-policy \
--role-name lambda-ex \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
--endpoint-url=http://127.0.0.1:4566

# Create a Lambda function with the create-function command.
# Replace the highlighted text in the role ARN with your account ID.
aws lambda create-function \
--function-name my-function \
--zip-file fileb://./my-math-function/my-deployment-package.zip \
--handler lambda_function.lambda_handler \
--runtime nodejs12.x \
--role arn:aws:iam::000000000000:role/lambda-ex \
--endpoint-url=http://127.0.0.1:4566

# To get logs for an invocation from the command line,
# use the --log-type option. The response includes a LogResult field
# that contains up to 4 KB of base64-encoded logs from the invocation.
aws lambda invoke \
--function-name my-function square 2 \
--log-type Tail \
--endpoint-url=http://127.0.0.1:4566

# You can use the base64 utility to decode the logs.
aws lambda invoke \
--function-name my-function out \
--payload '{ "action": "square", "number": 2 }' \
--log-type Tail \
--endpoint-url=http://127.0.0.1:4566 \
--query 'LogResult' --output text |  base64 -d

# Run the following AWS CLI list-functions command
# to retrieve a list of functions that you have created.
aws lambda list-functions \
--max-items 10 \
--endpoint-url=http://127.0.0.1:4566

# The Lambda CLI get-function command returns Lambda function metadata
# and a presigned URL that you can use
# to download the function's deployment package.
aws lambda get-function \
--function-name my-function \
--endpoint-url=http://127.0.0.1:4566

# Run the following delete-function command to delete the my-function function.
aws lambda delete-function \
--function-name my-function \
--endpoint-url=http://127.0.0.1:4566
