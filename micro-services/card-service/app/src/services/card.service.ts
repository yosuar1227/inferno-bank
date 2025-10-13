import { DynamoService } from "../database/dynamodb";
import { CardStatus, CardType } from "../enums/generic.enum";
import { generateRandomAmount } from "../functions/generic.functions";
import { Card } from "../types/card.type";
import { v4 as uuid } from "uuid";

export class CardService {
    private readonly dynamoDbService: DynamoService

    constructor() {
        this.dynamoDbService = new DynamoService()
    }

    /**
     * @description Method to create a card related to the incomming user id
     * @param userId
     * @param type The default values is DEBIT
     */
    async createCardRequest(userId: string, type = CardType.DEBIT) {
        return await this.cardExecution(type, userId);
    }

    private async cardExecution(type: string, userId: string) {
        try {
            const cardItem = this.buildCardItem(type, userId)

            return await this.dynamoDbService.put({
                item: cardItem,
                tableName: process.env.BankUserCardTable || ""
            });
        } catch (error) {
            console.log("ERROR IN DECIR CARD EXECUTION::", error);
            return null;
        }
    }

    private buildCardItem(type: string, userId: string) {
        let item: Card = {
            uuid: uuid(),
            user_id: userId,
            balance: 0,
            createdAt: new Date().toISOString(),
            status: CardStatus.ACTIVATED,
            type: CardType.DEBIT
        }

        if (type === CardType.CREDIT) {
            item = {
                ...item,
                balance: generateRandomAmount().amount,
                type: CardType.CREDIT,
                status: CardStatus.PENDING
            }
        }

        return item;
    }
}