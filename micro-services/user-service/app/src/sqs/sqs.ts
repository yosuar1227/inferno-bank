import { SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs"

interface ISqsPayload {
    queueUrl: string
    data: Record<string, any>
}

export class SqsService {
    private readonly sqsClient = new SQSClient({})

    constructor() { }

    async send(payload: ISqsPayload): Promise<void> {
        try {
            const command = new SendMessageCommand({
                QueueUrl: payload.queueUrl,
                MessageBody: JSON.stringify(payload.data),
            })

            const response = await this.sqsClient.send(command)
            console.log(response)
        } catch (error) {
            console.error(error)
        }
    }
}