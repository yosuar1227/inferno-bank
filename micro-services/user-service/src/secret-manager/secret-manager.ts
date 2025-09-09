import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";

export class SecretManager {
  private readonly client = new SecretsManagerClient({});

  constructor() {}

  async get<T>(secretName: string): Promise<T> {
    try {
      const command = new GetSecretValueCommand({
        SecretId: secretName,
      });

      const secret = await this.client.send(command);

      if (!secret.SecretString) {
        throw new Error("Secret not found");
      }

      return JSON.parse(secret.SecretString);
    } catch (error) {
      console.error("Error ar secret manager", error);
      throw error;
    }
  }
}
