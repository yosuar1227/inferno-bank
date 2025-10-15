import middy from "@middy/core";
import { CATALOG, PRODUCT_SERVICE_KEY } from "../constants/constants";
import { getRedisClient } from "../service/redis";
import { APIGatewayProxyResult } from "aws-lambda";

const getCatalogDataLambda = async (): Promise<APIGatewayProxyResult> => {
    const client = await getRedisClient();
    const key = `${PRODUCT_SERVICE_KEY}:${CATALOG}`;
    let msj = "KEY DOES NOT EXITS RETURING EMPTY LIST";
    let data: any = [];

    const redisData = await client.get(key);

    console.log("REDIS DATA::", redisData);

    if (redisData !== null) {
        msj = "KEY EXITS RETURING DATA";
        data = JSON.parse(redisData as string);
    }

    return {
        statusCode: 200,
        body: JSON.stringify({
            msj: msj,
            data: data,
        }),
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        },
    };
};

export const handler = middy<unknown, APIGatewayProxyResult>(
    getCatalogDataLambda
);
