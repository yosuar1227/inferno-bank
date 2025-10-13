import middy from "@middy/core";
import { SQSEvent } from "aws-lambda";
import { CardService } from "../services/card.service";
import { CardType } from "../enums/generic.enum";

interface IBatchItemFailure {
    itemIdentifier: string
}

const CARD_PROCCESOR_FOR_NEW_USER = "CARD_PROCCESOR_FOR_NEW_USER"

const createRequestCardProcessor = async (event: SQSEvent): Promise<IBatchItemFailure[]> => {
    const itemsFeilures: IBatchItemFailure[] = [];

    console.log("RECORD SIZE:::")
    console.log(event.Records.length)

    for (const e of event.Records) {
        const element = JSON.parse(e.body);
        try {

            if (element.type === CARD_PROCCESOR_FOR_NEW_USER) {
                const cardService = new CardService();
                const userId = element.data;

                const debitCardResponse = await cardService.createCardRequest(userId);
                const creditCardResponse = await cardService.createCardRequest(userId, CardType.CREDIT);

                console.log(debitCardResponse);
                console.log(creditCardResponse);
            }

            return []
        } catch (error) {
            itemsFeilures.push({ itemIdentifier: `Error proccesing the cards for user:: ${element.data}` })
        }
    }

    return itemsFeilures
}

export const handler = middy<SQSEvent, IBatchItemFailure[]>(createRequestCardProcessor)