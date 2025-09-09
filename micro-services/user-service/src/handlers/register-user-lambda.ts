import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import middy from "@middy/core";
import { v4 } from "uuid";
import { DynamoService } from "../database/dynamodb.js";
import httpErrorHandler from "@middy/http-error-handler";
import { schemaMiddleware } from "../middleware/schema.middleware.js";
import { userSchema } from "../schema/user.schema.js";

const registerUserLambda = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  const body = JSON.parse(event.body || "{}");

  const item = {
    uuid: v4(),
    create_at: new Date().toISOString(),
    ...body,
  };

  const resp = await new DynamoService().save({
    tableName: process.env.BankUserTable || "",
    item,
  });

  console.log("dynamo response", resp);

  return {
    statusCode: 200,
    body: JSON.stringify({ ...item }),
    headers: {
      "Content-type": "application/json",
    },
  };
};

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
  registerUserLambda
)
  .use(httpErrorHandler())
  .use(schemaMiddleware(userSchema));
