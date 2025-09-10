import middy from "@middy/core";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";

const updateProfileLambda = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    return {
        statusCode: 200,
        body: JSON.stringify({ msj: "update profile lambda working!!!" }),
        headers: {
            "Content-type": "application/json",
        },
    };
}

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
    updateProfileLambda
)