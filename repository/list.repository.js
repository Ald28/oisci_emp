import { prisma } from '../database/client.mjs'

export const ListClients = {
    async getAllClients() {
        return prisma.client.findMany({
            where: { active: true },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        role: true,
                    },
                },
            },
        })
    },
}