import { getUser } from "../service/data";
import { getRedisClient } from "../service/redis";


export const handler = async ({ target }: { target: string }) => {
    const client = await getRedisClient();
    const key = `user:${target}`;

    const exists = await client.exists(key);

    if (!exists) {
        const data = await getUser();
        await client.hSet(key, data);
        return data;
    }

    return await client.hGetAll(key);
}