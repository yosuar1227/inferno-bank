import { createClient } from "redis";

const redisEndpoint = process.env.REDIS_ENDPOINT;
const redisPort = process.env.REDIS_PORT || "6379";

let redisClient: ReturnType<typeof createClient> | null = null;

export const getRedisClient = async () => {
    if (!redisClient) {
        redisClient = createClient({
            socket: {
                host: redisEndpoint,
                port: parseInt(redisPort),
                tls: false,
            },
        });
        redisClient.on("error", (err) => console.log("REDIS CLIENT ERROR::", err));
        await redisClient.connect();
    };
    console.log("CONNECTED WITH SUCCESS");
    return redisClient;
};
