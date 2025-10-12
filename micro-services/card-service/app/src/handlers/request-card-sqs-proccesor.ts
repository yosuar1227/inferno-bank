import middy from "@middy/core";
import { SQSEvent } from "aws-lambda";

interface IBatchItemFailure {
    itemIdentifier: string
}

const createRequestCardProcessor = (event: SQSEvent): void => {
    console.log("RECORD SIZE:::")
    console.log(event.Records.length)

    for (const e of event.Records) {
        console.log(e.body)
    }
}

export const handler = middy<SQSEvent, void>(createRequestCardProcessor)