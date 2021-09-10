# How to run and use localstack for lambda + API gateway deployment

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
[video1](https://www.youtube.com/watch?v=uFsaiEhr1zs&t)

[video2](https://www.youtube.com/watch?v=uICnMaOP5yE)

[docs](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-custom-integrations.html)

## Diagram

    HTTP GET + Vars ┌─────────────────┐  Invocation + Vars ┌───────────────────┐
    ────────────────►                 ├────────────────────►                   │
                    │   API Gateway   │                    │  Lambda function  │
    ◄───────────────┤                 ◄────────────────────┤                   │
    HTTP RESPONSE   └─────────────────┘            Return  └───────────────────┘



## 0. Create Lambda
see [python lambda](../main/python/README.md)

## 1. Create rest api
```sh
$ aws apigateway create-rest-api \
--name TransactionApis \
--endpoint-url=http://127.0.0.1:4566
```

## 2. Get rest api id
```sh
$ aws apigateway get-rest-apis \
--endpoint-url=http://127.0.0.1:4566
```

## 3. Get parent id
```sh
$ aws apigateway get-resources \
--rest-api-id "ylrqlrpqkj" \
--endpoint-url=http://127.0.0.1:4566
```

## 4. Create resource
```sh
$ aws apigateway create-resource \
--rest-api-id "ylrqlrpqkj" \
--parent-id "q2ybhxdcnz" \
--path-part 'transactions' \
--endpoint-url=http://127.0.0.1:4566
```

## 5. Specify method
```sh
$ aws apigateway put-method \
--rest-api-id "ylrqlrpqkj" \
--resource-id "avpnmpbhjh" \
--http-method "GET" \
--authorization-type "NONE" \
--endpoint-url=http://127.0.0.1:4566
```

## 6. Create integration
[put-integration](https://docs.aws.amazon.com/cli/latest/reference/apigateway/put-integration.html)
```sh
$ aws apigateway put-integration \
--rest-api-id "ylrqlrpqkj" \
--resource-id "avpnmpbhjh" \
--http-method "GET" \
--type AWS_PROXY \
--integration-http-method POST \
--uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:my-function' \
--endpoint-url=http://127.0.0.1:4566
```


## 7. Create deployment
```sh
$ aws apigateway create-deployment \
--rest-api-id "ylrqlrpqkj" \
--stage-name "dev" \
--endpoint-url=http://127.0.0.1:4566
```


## 8. Check url

`http://localhost:4566/restapis/<rest-api-id>/<stage-name>/_user_request_/<resource path-part>?<variable_01>=<value>&<variable_02>=<value>...`
note: variables passed into python function

example
```
http://<localstack ip>:4566/restapis/<rest-api-id>/<stage-name>/_user_request_/transactions?transactionId=5&type=PURCHASE&amount=500
```
