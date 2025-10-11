import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import createHttpError from "http-errors";
import { schemaMiddleware } from "../middleware/schema.middleware.js";
import { updateUserSchema } from "../schema/user.schema.js";
import { DynamoService } from "../database/dynamodb.js";
import { VerifyTokenMiddlewar } from "../middleware/verifyToken.middleware.js";

const updateProfileLambda = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  const userId = event.pathParameters?.user_id;
  const body = JSON.parse(event.body || "{}");

  if (!userId) {
    throw createHttpError.BadRequest("Missing mandatory user_id value");
  }

  const userById = await new DynamoService().getByUserId(userId);

  console.log(JSON.stringify(userById));

  if (userById === null) {
    throw createHttpError.NotFound("Incorrect user id cannot found user");
  }

  const item = {
    ...userById,
    address: body.address,
    phone: body.phone,
  };

  console.log("new object to bd::", item);

  const response = await new DynamoService().save({
    tableName: process.env.BankUserTable || "",
    item: item,
  });

  console.log("User updated ", response);

  return {
    statusCode: 200,
    body: JSON.stringify({
      msj: `User with id ${userId} updated successfully`,
    }),
    headers: {
      "Content-type": "application/json",
    },
  };
};

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
  updateProfileLambda
)
  .use(httpErrorHandler())
  .use(VerifyTokenMiddlewar())
  .use(schemaMiddleware(updateUserSchema));
