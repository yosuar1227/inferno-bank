import { MiddlewareObj } from "@middy/core";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import { SecretManager } from "../secret-manager/secret-manager.js";
import createHttpError from "http-errors";
import jwt from "jsonwebtoken";

export const VerifyTokenMiddlewar = (): MiddlewareObj<
    APIGatewayEvent,
    APIGatewayProxyResult
> => {
    const before = async (request: any): Promise<void> => {
        // obtenemos la secret desde Secrets Manager
        const secretKey = await new SecretManager().get<{ key: string }>(
            process.env.secretBankName || ""
        );

        const authHeader =
            request.event.headers?.Authorization ||
            request.event.headers?.authorization;

        if (!authHeader) {
            throw new createHttpError.Unauthorized("Missing Authorization header");
        }

        try {
            const token = authHeader.replace("Bearer ", "");
            jwt.verify(token, secretKey.key);
            return;
        } catch {
            throw new createHttpError.Unauthorized("Invalid or expired token");
        }
    };

    return { before };
};
