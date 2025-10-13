import { CardStatus, CardType } from "../enums/generic.enum";

export type Card = {
    uuid: string,
    user_id: string,
    type: CardType,
    status: CardStatus,
    balance: number,
    createdAt: string,
}