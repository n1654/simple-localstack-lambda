# How to run and use localstack for lambda + API gateway deployment + DynamoDB

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

## References

[docs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-dynamo-db.html)

## Diagram

    HTTP METHODS +          INVOCATION +           AWS.DynamoDB.DocumentClient
     BODY                      VARIABLES             .get   .put   .delete

        │                         │                           │
        │                         │                           │
        │   ┌─────────────────┐   │   ┌───────────────────┐   │  ┌─────────────────┐
     ───┴───►                 ├───┴───►                   ├───┴──►                 │
            │   API Gateway   │       │  Lambda function  │      │     Dynamodb    │
     ◄──────┤                 ◄───────┤                   ◄──────┤                 │
            └─────────────────┘       └───────────────────┘      └─────────────────┘


## 0. Configuration features
 - add hostname variable to docker-compose file
 `      - HOSTNAME_EXTERNAL=localstack`
 - nodejs function points to this hostname
 `const dynamo = new AWS.DynamoDB.DocumentClient({endpoint: 'http://${process.env.LOCALSTACK_HOSTNAME}:4566'});`
 - use [run.sh](../main/js_and_api_gw_and_dynamodb/run.sh) to execute aws cli commands automatically


## 1. Create a DynamoDB table

```sh
$ aws dynamodb create-table \
--table-name http-crud-tutorial-items \
--attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=name,AttributeType=S \
--key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=name,KeyType=RANGE \
--provisioned-throughput \
    ReadCapacityUnits=10,WriteCapacityUnits=5 \
--endpoint-url=http://127.0.0.1:4566
```

## 2. Create a Lambda function

### 2.1.Create role
[policies](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-policy-template-list.html)
```sh
$ aws iam create-role \
--role-name http-crud-tutorial-role \
--assume-role-policy-document file://trust-policy.json \
--endpoint-url=http://127.0.0.1:4566
```

### 2.2. Permissions
```sh
$ aws iam attach-role-policy \
--role-name http-crud-tutorial-role \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
--endpoint-url=http://127.0.0.1:4566
```

### 2.3. Lambda function
```sh
$ aws lambda create-function \
--function-name lambda_handler \
--zip-file fileb://./my-deployment-package.zip \
--handler http-crud-tutorial-function.handler \
--runtime nodejs12.x \
--role arn:aws:iam::000000000000:role/http-crud-tutorial-role \
--endpoint-url=http://127.0.0.1:4566
```


## 3. Create an HTTP API

### 3.1. Rest API
```sh
$ aws apigateway create-rest-api \
--name http-crud-tutorial-api \
--endpoint-url=http://127.0.0.1:4566
```

### 3.2 Get rest api id
```sh
$ aws apigateway get-rest-apis \
--endpoint-url=http://127.0.0.1:4566
```

### 3.3 Get parent id
```sh
$ aws apigateway get-resources \
--rest-api-id "p9ngobf7am" \
--endpoint-url=http://127.0.0.1:4566
```

## 4. Create routes
`/items`

```sh
$ aws apigateway create-resource \
--rest-api-id "p9ngobf7am" \
--parent-id "id2yyz1ldp" \
--path-part 'items' \
--endpoint-url=http://127.0.0.1:4566
```
btxnp9yhjp

`/items GET`
```sh
$ aws apigateway put-method \
--rest-api-id "p9ngobf7am" \
--resource-id "btxnp9yhjp" \
--http-method "GET" \
--authorization-type "NONE" \
--endpoint-url=http://127.0.0.1:4566
```

`/items PUT`
```sh
$ aws apigateway put-method \
--rest-api-id "p9ngobf7am" \
--resource-id "btxnp9yhjp" \
--http-method "PUT" \
--authorization-type "NONE" \
--endpoint-url=http://127.0.0.1:4566
```

`/items/{id}`

```sh
$ aws apigateway create-resource \
--rest-api-id "p9ngobf7am" \
--parent-id "btxnp9yhjp" \
--path-part '{id}' \
--endpoint-url=http://127.0.0.1:4566
```
7o8iu6s7kk

`/items/{id} GET`
```sh
$ aws apigateway put-method \
--rest-api-id "p9ngobf7am" \
--resource-id "7o8iu6s7kk" \
--http-method "GET" \
--authorization-type "NONE" \
--endpoint-url=http://127.0.0.1:4566
```

`/items/{id} DELETE`
```sh
$ aws apigateway put-method \
--rest-api-id "p9ngobf7am" \
--resource-id "7o8iu6s7kk" \
--http-method "DELETE" \
--authorization-type "NONE" \
--endpoint-url=http://127.0.0.1:4566
```

## 5. Create integration
[put-integration](https://docs.aws.amazon.com/cli/latest/reference/apigateway/put-integration.html)
[Integration types](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-integration-types.html)
[AWS PROXY -> lambda input format](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format)

`/items GET -> lambda`
```sh
$ aws apigateway put-integration \
--rest-api-id "p9ngobf7am" \
--resource-id "btxnp9yhjp" \
--http-method "GET" \
--type AWS_PROXY \
--integration-http-method GET \
--uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:lambda_handler' \
--endpoint-url=http://127.0.0.1:4566
```

`/items PUT -> lambda`
```sh
$ aws apigateway put-integration \
--rest-api-id "p9ngobf7am" \
--resource-id "btxnp9yhjp" \
--http-method "PUT" \
--type AWS_PROXY \
--integration-http-method PUT \
--uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:lambda_handler' \
--endpoint-url=http://127.0.0.1:4566
```

`/items/{id} GET -> lambda`
```sh
$ aws apigateway put-integration \
--rest-api-id "p9ngobf7am" \
--resource-id "7o8iu6s7kk" \
--http-method "GET" \
--type AWS_PROXY \
--integration-http-method "GET" \
--uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:lambda_handler' \
--endpoint-url=http://127.0.0.1:4566
```

`/items/{id} DELETE -> lambda`
```sh
$ aws apigateway put-integration \
--rest-api-id "p9ngobf7am" \
--resource-id "7o8iu6s7kk" \
--http-method "DELETE" \
--type AWS_PROXY \
--integration-http-method "DELETE" \
--uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:lambda_handler' \
--endpoint-url=http://127.0.0.1:4566
```

## 6. Create deployment
```sh
$ aws apigateway create-deployment \
--rest-api-id "p9ngobf7am" \
--stage-name "dev" \
--endpoint-url=http://127.0.0.1:4566
```

## 7. Test API

Create item
```sh
curl -v -X "PUT" -H "Content-Type: application/json" \
-d "{\"id\": \"abcdef234\"}" \
http://localhost:4566/restapis/y05sj46rau/dev/_user_request_/items
```


Check all items
```sh
curl -v http://localhost:4566/restapis/y05sj46rau/dev/_user_request_/items
```
