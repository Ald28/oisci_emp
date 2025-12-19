import { prisma } from '../../database/client.mjs'

export const ListClients = {
    async searchClients(search) {
        const where = {
            active: true,
        }

        if (search && search.trim() !== '') {
            where.OR = [
                {
                    ruc: {
                        contains: search,
                    },
                },
                {
                    razonSocial: {
                        contains: search,
                        mode: 'insensitive',
                    },
                },
            ]
        }

        return prisma.client.findMany({
            where,
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

    async listClients(search) {
        return this.searchClients(search)
    },
}