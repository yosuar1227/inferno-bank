import Joi from "joi";

export const userSchema = Joi.object({
    name: Joi.string().required(),
    lastName: Joi.string().required(),
    email: Joi.string().email().required(),
    password: Joi.string().required(),
    document: Joi.number().required(),
})

export const userLoginSchema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
})

export const updateUserSchema = Joi.object({
    address: Joi.string().required(),
    phone: Joi.number().required(),
})

export const userAvatarSchema = Joi.object({
    name: Joi.string().required(),
    image: Joi.string().required(),
    fileType: Joi.string().required(),
})