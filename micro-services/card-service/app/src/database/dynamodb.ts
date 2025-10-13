import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

interface IDynamoCommand {
    tableName: string;
    item: Record<string, any>;
}

export class DynamoService {
    private readonly client = DynamoDBDocumentClient.from(
        new DynamoDBClient({}),
        {
            marshallOptions: {
                convertClassInstanceToMap: true,
                removeUndefinedValues: true
            }
        }
    );


    constructor() { }

    async put(command: IDynamoCommand) {
        try {
            const response = await this.client.send(
                new PutCommand({
                    TableName: command.tableName,
                    Item: command.item,
                })
            );

            return response;
        } catch (error) {
            console.error("Error saving in dynamo db ", error);
            return null;
        }
    }

}