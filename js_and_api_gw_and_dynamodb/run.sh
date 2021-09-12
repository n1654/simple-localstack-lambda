#!/bin/bash

set -e
unset rest_api_id
unset rest_api_parent_id
unset res1_id
unset res2_id


function prep_zip_pkg {
    rm my-deployment-package.zip
    zip my-deployment-package.zip http-crud-tutorial-function.js
}

function cr_dyndb_table {
    res=` \
        aws dynamodb create-table \
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
    `
    echo "OK"
}

function cr_role {
    res=` \
        aws iam create-role \
            --role-name http-crud-tutorial-role \
            --assume-role-policy-document file://trust-policy.json \
            --endpoint-url=http://127.0.0.1:4566
    `
    echo "OK"
}

function att_role {
    res=` \
        aws iam attach-role-policy \
            --role-name http-crud-tutorial-role \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
            --endpoint-url=http://127.0.0.1:4566
    `
    echo "OK"
}

function cr_lambda {
    res=` \
        aws lambda create-function \
            --function-name lambda_handler \
            --zip-file fileb://./my-deployment-package.zip \
            --handler http-crud-tutorial-function.handler \
            --runtime nodejs12.x \
            --role arn:aws:iam::000000000000:role/http-crud-tutorial-role \
            --endpoint-url=http://127.0.0.1:4566
    `
    echo "OK"
}

function cr_rest_api {
    api_id=` \
        aws apigateway create-rest-api \
            --name http-crud-tutorial-api \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $4}'
    `
    echo $api_id
}

function get_rest_api_parent_id {
    rest_api_parent_id=` \
        aws apigateway get-resources \
            --rest-api-id "$1" \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $2}'
    `
    echo $rest_api_parent_id
}

function create_resource {
    res_id=` \
        aws apigateway create-resource \
            --rest-api-id "$1" \
            --parent-id "$2" \
            --path-part $3 \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $1}'
    `
    echo $res_id
}

function put_method {
    res=` \
        aws apigateway put-method \
            --rest-api-id "$1" \
            --resource-id "$2" \
            --http-method $3 \
            --authorization-type "NONE" \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $3}'
    `
    echo $res
}

function put_integration {
    res=` \
        aws apigateway put-integration \
            --rest-api-id "$1" \
            --resource-id "$2" \
            --http-method $3 \
            --type $4 \
            --integration-http-method $5 \
            --uri 'arn:aws:apigateway:ap-southeast-2:lambda:path//2015-03-31/functions/arn:aws:lambda:ap-southeast-2:000000000000:function:lambda_handler' \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $2}'
    `
    echo $res
}

function create_deployment {
    res=` \
        aws apigateway create-deployment \
            --rest-api-id "$1" \
            --stage-name $2 \
            --endpoint-url=http://127.0.0.1:4566 \
            --output text | head -n 1 | awk '{print $2}'
    `
    echo $res
}

function main {
    echo "PREPARING FUNCTION ZIP PACKAGE..."
    prep_zip_pkg

    echo "CREATING DYNAMODB TABLE..."
    cr_dyndb_table

    echo "CREATING ROLE..."
    cr_role

    echo "ATTACHING ROLE..."
    att_role

    echo "CREATING LAMBDA FUNCTION..."
    cr_lambda

    echo "CREATING REST API..."
    rest_api_id=$(cr_rest_api)

    echo "REST API ID:" $rest_api_id
    rest_api_parent_id=$(get_rest_api_parent_id $rest_api_id)
    echo "REST API PARENT ID:" $rest_api_parent_id

    echo "CREATING ROUTE /items..."
    res1_id=$(create_resource $rest_api_id $rest_api_parent_id "items")
    echo "RESOURCE ID:" $res1_id

    echo "PUTTING METHODs..."
    put_method $rest_api_id $res1_id "GET"
    put_method $rest_api_id $res1_id "PUT"

    echo "CREATING ROUTE /items/{id}..."
    res2_id=$(create_resource $rest_api_id $res1_id "{id}")
    echo "RESOURCE ID:" $res2_id

    echo "PUTTING METHODs..."
    put_method $rest_api_id $res2_id "GET"
    put_method $rest_api_id $res2_id "DELETE"

    echo "PUTTING INTEGRATIONs..."
    put_integration $rest_api_id $res1_id "GET" "AWS_PROXY" "GET"
    put_integration $rest_api_id $res1_id "PUT" "AWS_PROXY" "PUT"
    put_integration $rest_api_id $res2_id "GET" "AWS_PROXY" "GET"
    put_integration $rest_api_id $res2_id "DELETE" "AWS_PROXY" "DELETE"

    echo "CREATING DEPLOYMENT..."
    create_deployment $rest_api_id "dev"

    echo "TEST COMMANDS"
    echo "(1) list items"
    echo "curl -v http://localhost:4566/restapis/$rest_api_id/dev/_user_request_/items"
    echo "(2) create item"
    echo 'curl -v -X "PUT" -H "Content-Type: application/json" -d "{\"id\": \"abcdef234\", \"price\": 12345, \"name\": \"myitem\"}" http://localhost:4566/restapis/'$rest_api_id'/dev/_user_request_/items'
    echo "(3) get item"
    echo "curl -v http://localhost:4566/restapis/$rest_api_id/dev/_user_request_/items/abcdef234"
    echo "(4) delete item"
    echo 'curl -v -X "DELETE" http://localhost:4566/restapis/'$res_api_id'/dev/_user_request_/items/abcdef234'
}

main "$@"
