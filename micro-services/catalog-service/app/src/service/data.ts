import { faker } from "@faker-js/faker";

export const getUser = (): Promise<Record<string, any>> => {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve({
                username: faker.internet.username(),
                email: faker.internet.email(),
                avatar: faker.image.avatar(),
            });
        }, 5000); //5seg para simular una peticion a la BD
    });
};
