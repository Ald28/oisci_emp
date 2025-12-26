import { prisma } from '../../database/client.mjs';

export const CreateSedeRepository = {
    async create(data) {
        const {
            name_sede,
            address,
            manager_name,
            manager_phone,
            manager_email,
            city,
            clientId,
        } = data;

        return prisma.sede.create({
            data: {
                name_sede,
                address,
                manager_name,
                manager_phone,
                manager_email,
                city,
                clientId,
            },
            include: {
                client: true,
                extintores: true,
            },
        });
    },
};