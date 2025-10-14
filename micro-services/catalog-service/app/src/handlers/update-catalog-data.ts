import middy from "@middy/core";
import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import { parse } from "csv-parse/sync";
import createHttpError from "http-errors";
import { S3Service } from "../s3/s3";
import { getRedisClient } from "../service/redis";
import { CATALOG, PRODUCT_SERVICE_KEY } from "../constants/constants";


const updateCatalogData = async (
    event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
    console.log(event.body)
    try {
        if (!event.body) {
            throw createHttpError.BadRequest("CSV file not received")
        }

        const isBase64 = event.isBase64Encoded;
        const csvInfo = isBase64
            ? Buffer.from(event.body || "", "base64").toString("utf-8")
            : event.body || "";


        const records: any[] = parse(csvInfo, {
            columns: true,          // converts each row into an object with keys = headers
            skip_empty_lines: true, // ignore empty lines
            relax_column_count: true,
            relax_quotes: true,
            delimiter: autoDetectDelimiter(csvInfo), // detects delimiter
        })

        console.log(records)

        await new S3Service().uploadCsvFile({
            bucket: process.env.fileBucket || "",
            data: csvInfo,
            name: `catalog-${Date.now()}`
        });

        const redisClient = await getRedisClient();
        const key = `${PRODUCT_SERVICE_KEY}:${CATALOG}`;

        await redisClient.set(key, JSON.stringify(records));


        return {
            statusCode: 200,
            body: JSON.stringify({
                msj: "Catalog updated with the following data.",
                data: records
            }),
            headers: {
                "Content-type": "application/json",
            },
        };
    } catch (error) {
        console.log("ERROR DETECTED::", error)
        throw createHttpError.InternalServerError("Error processing CSV file")
    }
}

const autoDetectDelimiter = (content: string): string => {
    const sample = content.split('\n')[0] || ''
    const candidates = [',', ';', '\t', '|', ':']
    let bestDelimiter = ','
    let maxCount = 0
    for (const d of candidates) {
        const count = (sample.match(new RegExp(`\\${d}`, 'g')) || []).length
        if (count > maxCount) {
            bestDelimiter = d
            maxCount = count
        }
    }
    return bestDelimiter
}

export const handler = middy<APIGatewayEvent, APIGatewayProxyResult>(updateCatalogData)