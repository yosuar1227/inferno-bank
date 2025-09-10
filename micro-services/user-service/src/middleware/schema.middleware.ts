import { MiddlewareObj } from "@middy/core";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import createHttpError from "http-errors";
import Joi from "joi";

export const schemaMiddleware = (
    schema: Joi.Schema
): MiddlewareObj<APIGatewayEvent, APIGatewayProxyResult> => {
    return {
        before(request) {
            const body = JSON.parse(request.event.body || "{}")
            const { error } = schema.validate(body)
            if (error) {
                throw createHttpError.BadRequest(JSON.stringify({
                    msg: "There is missing mandatory data or unknown data > " + JSON.stringify(error)
                }))
            }
            return
        }
    }
};
