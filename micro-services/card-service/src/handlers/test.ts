import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import middy from "@middy/core";

const testEvent = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    return {
        statusCode: 200,
        body: JSON.stringify({ msj: "Hello world.." }),
        headers: {
            "Content-type": "application/json"
        }
    }
};

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
    testEvent
);
