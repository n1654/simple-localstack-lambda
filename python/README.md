# How to run and use localstack for lambda deployment

## Environment

| HyperVisor | VirtualBox 6.1 |
| ------ | ------ |

| Virtual Machine |  |
| ------ | ------ |
| vCPU | 2 |
| RAM | 4096 MB |
| Disk | 30 GB |
| OS | Ubuntu 20.04.1 LTS |
| Docker | Community 20.10.2 |
| Docker-compose | 1.27.4 |
| Python | 3.8.10 |
| Localstack | 0.12.17.5 |
| Aws-cli | 1.20.37 |

## 1. Clone localstack and do read documentation carefully:
From [here](https://github.com/localstack/localstack)

### SERVICES
Read here [SERVICES](https://github.com/localstack/localstack#core-configurations)
Change `docker-compose.yaml`
```
- SERVICES=serverless
```
this will launch only the services required for lambda application

### LAMBDA_EXECUTOR
Read here [LAMBDA_EXECUTOR](https://github.com/localstack/localstack#lambda-configurations)
Make sure that LAMBDA_EXECUTOR is set to `docker`. Default setting is `docker`.
```
- LAMBDA_EXECUTOR=${LAMBDA_EXECUTOR- }
```
### TMPDIR
TMPDIR: Temporary folder inside the LocalStack container (default: /tmp).
Create temp dir for localstack (you will you this folder when spin up localstack, see 3.)

## 2. AWS CLI v1 (bundle)
### 2.1. Install
Requires `python vitual environment` installed
Aws cli [how to install](https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html)

### 2.2. Configure AWS CLI
```sh
$ aws configure
AWS Access Key ID [None]: 123
AWS Secret Access Key [None]: 123
Default region name [None]: ap-southeast-2
Default output format [None]:
```

## 3. Spin up localstack
```
$ TMPDIR=./localstack-temp/.localstack DEBUG=1 docker-compose up
```

Once sucessfylly completed you should see message similar to this
```
localstack_main | Ready.
```

You may also want to check API response:
```sh
$ curl http://localhost:4566/health | python3 -m json.tool
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   332  100   332    0     0  30181      0 --:--:-- --:--:-- --:--:-- 30181
{
    "services": {
        "cloudformation": "running",
        "cloudwatch": "running",
        "dynamodb": "running",
        "dynamodbstreams": "running",
        "iam": "running",
        "sts": "running",
        "kinesis": "running",
        "lambda": "running",
        "logs": "running",
        "s3": "running",
        "apigateway": "running"
    },
    "features": {
        "persistence": "disabled",
        "initScripts": "initialized"
    }
}
```

## 4. Prepare function
Prepare Python function as [here](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)

### 4.1. For instance you can use next function
[lambda_function.py]: https://github.com/n1654/simple-localstack-lambda/blob/main/python/my-math-function/lambda_function.py

### 4.2. Zip it
example
```sh
$ zip my-deployment-package.zip lambda_function.py
```

## 5. Spin up Lambda
For more information read aws guide [reference](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-awscli.html)

All the commands point to localstack API with this:
`--endpoint-url=http://127.0.0.1:4566`

### 5.1. Execution Role
Create the execution role that gives your function permission to access AWS resources. To create an execution role with the AWS CLI, use the create-role command.
```sh
$ aws iam create-role \
--role-name lambda-ex \
--assume-role-policy-document file://trust-policy.json \
--endpoint-url=http://127.0.0.1:4566
```

### 5.2. Permissions
To add permissions to the role, use the attach-policy-to-role command. Start by adding the AWSLambdaBasicExecutionRole managed policy. The AWSLambdaBasicExecutionRole policy has the permissions that the function needs to write logs to CloudWatch Logs.
```sh
$ aws iam attach-role-policy \
--role-name lambda-ex \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
--endpoint-url=http://127.0.0.1:4566
```

### 5.3. Create a Lambda function
Create a Lambda function with the create-function command. Replace the highlighted text in the role ARN with your account ID.
```sh
$ aws lambda create-function \
--function-name my-function \
--zip-file fileb://./my-math-function/my-deployment-package.zip \
--handler lambda_function.lambda_handler \
--runtime python3.8 \
--role arn:aws:iam::000000000000:role/lambda-ex \
--endpoint-url=http://127.0.0.1:4566
```

`handlers` described [here](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
the construction simply composed of <function_name>.<method_name>
`runtimes` described [here](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
`payload` --payload (blob)
The JSON that you want to provide to your Lambda function as input.

### 5.4 Launch Lambda function
To get logs for an invocation from the command line, use the --log-type option. The response includes a LogResult field that contains up to 4 KB of base64-encoded logs from the invocation.
```sh
$ aws lambda invoke \
--function-name my-function out \
--payload '{ "action": "square", "number": 2 }' \
--log-type Tail \
--endpoint-url=http://127.0.0.1:4566
```

### 5.5. Launch Lambda function and check logs
You can use the base64 utility to decode the logs.
```sh
aws lambda invoke \
--function-name my-function out \
--payload '{ "action": "square", "number": 2 }' \
--log-type Tail \
--endpoint-url=http://127.0.0.1:4566 \
--query 'LogResult' --output text |  base64 -d
```

### 5.6. List functions
Run the following AWS CLI list-functions command to retrieve a list of functions that you have created.
```sh
aws lambda list-functions \
--max-items 10 \
--endpoint-url=http://127.0.0.1:4566
```

### 5.7. Get function
The Lambda CLI get-function command returns Lambda function metadata and a presigned URL that you can use to download the function's deployment package.
```sh
$ aws lambda get-function \
--function-name my-function \
--endpoint-url=http://127.0.0.1:4566
```

### 5.8. Delete function
Run the following delete-function command to delete the my-function function.
```sh
$ aws lambda delete-function \
--function-name my-function \
--endpoint-url=http://127.0.0.1:4566
```
