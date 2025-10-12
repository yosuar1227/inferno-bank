import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import createHttpError from "http-errors";
import { VerifyTokenMiddlewar } from "../middleware/verifyToken.middleware";
import { DynamoService } from "../database/dynamodb";
import { S3Service } from "../s3/s3";

const getUserProfileLambda = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    const userId = event.pathParameters?.user_id;

    if (!userId) {
        throw createHttpError.BadRequest("Missing mandatory user_id value");
    }

    let userById = await new DynamoService().getByUserId(userId);

    if (userById === undefined || userById === null) {
        throw createHttpError.NotFound("Incorrect user id cannot found user");
    }

    if (userById?.image) {
        const imageKey = userById.image.split("/").pop(); //image/files-bucket-storage-yosuar-mieles/perfil-1760229778342 -> perfil-1760229778342
        const urlImage = await new S3Service()
        .getUrl(
            process.env.fileBucket || "",
            imageKey
        )

        userById = {
            ...userById,
            image: urlImage
        }
    }

    return {
        statusCode: 200,
        body: JSON.stringify(userById),
        headers: {
            "Content-type": "application/json",
        }
    }
}


export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(
    getUserProfileLambda
)
    .use(httpErrorHandler())
    .use(VerifyTokenMiddlewar())