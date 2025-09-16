import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import { VerifyTokenMiddlewar } from "../middleware/verifyToken.middleware.js";

const addUserAvatarLambda = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    return {
        statusCode: 200,
        body: "add user avantar working!!",
        headers: {
            "Content-type": "application/json",
        }
    }
}

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
    addUserAvatarLambda
)
    .use(httpErrorHandler())
    .use(VerifyTokenMiddlewar())