import middy from "@middy/core";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoService } from "../database/dynamodb.js";
import createHttpError from "http-errors";
import { HashService } from "../hash/hash.js";
import { SecretManager } from "../secret-manager/secret-manager.js";
import httpErrorHandler from "@middy/http-error-handler";

const userLoginLambda = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  const body = JSON.parse(event.body || "{}");

  const user = await new DynamoService().getByEmail(body.email);

  if (user === null) {
    throw createHttpError.BadRequest("Invalid credentials");
  }

  const saltValue = await getSecretValue();

  const isPasswordCorrect = new HashService(saltValue).compare(
    body.password,
    user?.password
  );

  if (!isPasswordCorrect) {
    throw createHttpError.Unauthorized("The email or password is incorrect ");
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ msj: "user logged in successfully" }),
    headers: {
      "Content-type": "application/json",
    },
  };
};

const getSecretValue = async () => {
  const secret = await new SecretManager().get<{ key: string }>(
    process.env.secretBankName || ""
  );
  return secret.key;
};

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
  userLoginLambda
).use(httpErrorHandler());
