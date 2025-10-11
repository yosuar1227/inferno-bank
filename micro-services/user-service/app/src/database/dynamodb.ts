import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
} from "@aws-sdk/lib-dynamodb";

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
        removeUndefinedValues: true,
      },
    }
  );

  constructor() { }

  async save(command: IDynamoCommand) {
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
    }
  }

  async get(pid: string) {
    try {
      const comand = new GetCommand({
        TableName: process.env.BankUserTable || "",
        Key: {
          uuid: pid,
        },
      });

      const response = await this.client.send(comand);

      return response.Item || null;
    } catch (error) {
      console.error("Error getting the item", error);
      return null;
    }
  }

  async getByUserId(userId: string) {
    try {
      const command = new QueryCommand({
        TableName: process.env.BankUserTable || "",
        KeyConditionExpression: "#u = :uuid",
        ExpressionAttributeNames: {
          "#u": "uuid"
        },
        ExpressionAttributeValues: {
          ":uuid": userId,
        },
      });

      const response = await this.client.send(command);

      return response.Items?.[0] || [];
    } catch (error) {
      console.error("Error getting user by id", error);
    }
  }

  async getByEmail(email: string) {
    try {
      const command = new QueryCommand({
        TableName: process.env.BankUserTable || "",
        IndexName: process.env.BankEmailIndex || "",
        KeyConditionExpression: "email = :e",
        ExpressionAttributeValues: {
          ":e": email,
        },
      });

      const response = await this.client.send(command);
      return response.Items?.[0] ?? null;
    } catch (error) {
      console.error("Error getting the dynamo db", error);
    }
  }
}
