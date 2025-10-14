import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";

interface IS3Payload {
    data: string,
    bucket: string,
    name: string,
}

export class S3Service {
    private readonly s3Client = new S3Client({})

    constructor() { }


    async uploadCsvFile(payload: IS3Payload): Promise<void> {
        try {
            // Array de tipo Buffer
            const body = Buffer.from(payload.data, "utf-8");
            console.log("body", body);

            const params = new PutObjectCommand({
                Bucket: payload.bucket,
                Key: payload.name,
                Body: body,
                ContentType: "text/csv"
            });

            console.log("params", params);

            const rest = await this.s3Client.send(params);

            console.log("S3 RESPONSE::", rest);
        } catch (error) {
            console.error(error)
            throw error
        }
    }

}