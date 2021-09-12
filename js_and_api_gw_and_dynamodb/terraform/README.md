# TERRAFORM lambda + API gateway deployment + DynamoDB

Terraform v0.14.6

## STEPS

### 1. Initialize
in `terraform` directory execute
```sh
$ terraform init
```

### 2. Plan
```sh
$ terraform plan -out "all-in-one"
```

### 3. Apply
```sh
$ terraform apply "all-in-one"
```

### 4. Verify
Check output from `apply` command and find `rest-api-id`:

`aws_api_gateway_rest_api.http-crud-tutorial-api: Creation complete after 0s [id=5e4blfa12u]`

replace <rest-api-id> and verify:

```sh
$ curl -v -X "PUT" -H "Content-Type: application/json" \
-d "{\"id\": \"abcdef234\", \"price\": 12345, \"name\": \"myitem\"}" \
http://localhost:4566/restapis/<rest-api-id>/dev/_user_request_/items
```

```sh
$ curl -v http://localhost:4566/restapis/<rest-api-id>/dev/_user_request_/items
```

```sh
$ curl -v http://localhost:4566/restapis/<rest-api-id>/dev/_user_request_/items/abcdef234
```

```sh
$ curl -v -X "DELETE" http://localhost:4566/restapis/<rest-api-id>/dev/_user_request_/items/abcdef234
```
