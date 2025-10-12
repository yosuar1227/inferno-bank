import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import { VerifyTokenMiddlewar } from "../middleware/verifyToken.middleware.js";
import { schemaMiddleware } from "../middleware/schema.middleware.js";
import { userAvatarSchema } from "../schema/user.schema.js";
import { S3Service } from "../s3/s3.js";
import createHttpError from "http-errors";
import { DynamoService } from "../database/dynamodb.js";

const addUserAvatarLambda = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    const userId = event.pathParameters?.user_id;

    if (!userId) {
        throw createHttpError.BadRequest("Missing mandatory user_id value");
    }

    const userById = await new DynamoService().getByUserId(userId);

    console.log("USER BY IDED FOUND", userById)

    if (userById === null) {
        throw createHttpError.NotFound("Incorrect user id cannot found user");
    }

    const body = JSON.parse(event.body || "{}");

    const imageName = `${body.name}-${Date.now()}`;


    await new S3Service().upload({
        bucket: process.env.fileBucket || "",
        contentType: body.fileType,
        data: body.image,
        name: imageName
    });

    const userWithAvatar = {
        ...userById,
        image: `image/${process.env.fileBucket}/${imageName}`
    };

    console.log("new object for user", userWithAvatar)

    const response = await new DynamoService().save({
        tableName: process.env.BankUserTable || "",
        item: userWithAvatar,
    });

    console.log("User updated ", response);

    return {
        statusCode: 200,
        body: JSON.stringify({
            msj: `avatar added successfully for User with id ${userId}`,
        }),
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
    .use(schemaMiddleware(userAvatarSchema));