import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

interface IS3Payload {
    data: string,
    contentType: string,
    bucket: string,
    name: string,
}

export class S3Service {
    private readonly s3Client = new S3Client({})

    constructor() { }


    async upload(payload: IS3Payload): Promise<void> {
        try {
            // Array de tipo Buffer
            const body = Buffer.from(
                payload.data.replace(/^data:image\/\w+;base64,/, ""),
                "base64"
            )
            console.log("body", body)


            const params = new PutObjectCommand({
                Bucket: payload.bucket,
                Key: payload.name,
                Body: body,
                //ACL: "public-read", //la forma en la que puedes acceder al dato
                ContentEncoding: "base64",
                ContentType: payload.contentType
            })

            console.log("params", params)


            const rest = await this.s3Client.send(params)
            console.log("res S3::", rest);
        } catch (error) {
            console.error(error)
            throw error
        }
    }

    async getUrl(bucket: string, key: string): Promise<string> {
        try {
            const command = new GetObjectCommand({
                Bucket: bucket,
                Key: key
            })

            const url = await getSignedUrl(this.s3Client, command, {
                expiresIn: 3600 //1H
            })

            return url
        } catch (error) {
            console.error("Error at signing url", error)
            throw error
        }
    }
}