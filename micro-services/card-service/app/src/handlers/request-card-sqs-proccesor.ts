import middy from "@middy/core";
import { SQSEvent } from "aws-lambda";

interface IBatchItemFailure {
    itemIdentifier: string
}

const createRequestCardProcessor = (event: SQSEvent): IBatchItemFailure[] => {

    const batchItemFailure: IBatchItemFailure[] = []

    for (const e of event.Records) {
        try {
            console.log("READING BODY>>>", JSON.parse(e.body))
        } catch (error) {
            batchItemFailure.push({ itemIdentifier: e.messageId })
            batchItemFailure.push({ itemIdentifier: JSON.stringify(e.messageAttributes)})
        }
    }

    console.log("CALLING THE CREATE REQUEST CARRD PROCESSOR WITH SQS EVENT")
    console.log("BATCH ITEMS:::", batchItemFailure);
    return batchItemFailure
}

export const handler = middy<SQSEvent, IBatchItemFailure[]>(createRequestCardProcessor)