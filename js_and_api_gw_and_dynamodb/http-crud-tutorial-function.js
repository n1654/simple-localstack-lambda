const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient({endpoint: `http://${process.env.LOCALSTACK_HOSTNAME}:4566`});

exports.handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json"
  };

  try {
    if (event.httpMethod=="DELETE" && event.resource=="/items/{id}") {
        await dynamo
          .delete({
            TableName: "http-crud-tutorial-items",
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
        body = `Deleted item ${event.pathParameters.id}`;
    } else if (event.httpMethod=="GET" && event.resource=="/items/{id}") {
        body = await dynamo
          .get({
            TableName: "http-crud-tutorial-items",
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
    } else if (event.httpMethod=="GET" && event.resource=="/items") {
        body = await dynamo.scan({ TableName: "http-crud-tutorial-items" }).promise();
    } else if (event.httpMethod=="PUT" && event.resource=="/items") {
        let requestJSON = JSON.parse(event.body);
        await dynamo
          .put({
            TableName: "http-crud-tutorial-items",
            Item: {
              id: requestJSON.id,
              price: requestJSON.price,
              name: requestJSON.name
            }
          })
          .promise();
        body = `Put item ${requestJSON.id}`;
    } else {
        console.log(JSON.stringify(event));
        throw new Error(`Unsupported route,  httpMethod: "${event.httpMethod}", resource: "${event.resource}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers
  };
};
