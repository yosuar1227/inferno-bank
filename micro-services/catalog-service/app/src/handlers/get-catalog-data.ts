import middy from "@middy/core";
import { CATALOG, PRODUCT_SERVICE_KEY } from "../constants/constants";
import { getRedisClient } from "../service/redis";
import { APIGatewayProxyResult } from "aws-lambda";

const getCatalogDataLambda = async (): Promise<APIGatewayProxyResult> => {
    const client = await getRedisClient();
    const key = `${PRODUCT_SERVICE_KEY}:${CATALOG}`;
    let msj = "";
    let data: any = null;

    const keyExits = await client.exists(key);

    if (keyExits) {
        msj = "KEY EXITS RETURING DATA";
        data = await client.hGetAll(key);
    }

    msj = "KEY DOES NOT EXITS RETURING EMPTY LIST";
    data = [];

    return {
        statusCode: 200,
        body: JSON.stringify({
            msj: msj,
            data: data,
        }),
        headers: {
            "Content-type": "application/json",
        },
    };
};

export const handler = middy<unknown, APIGatewayProxyResult>(
    getCatalogDataLambda
);
