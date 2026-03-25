import { prisma } from '../../database/client.mjs'

export const ListClients = {
    async searchClients(search, page = 1, pageSize = 10, all = false) {
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

        const include = {
            user: {
                select: {
                    id: true,
                    name: true,
                    email: true,
                    role: true,
                },
            },
            sedes: {
                where: {
                    active: true,
                },
                select: {
                    id: true,
                    name_sede: true,
                    address: true,
                    city: true,
                    manager_name: true,
                    manager_phone: true,
                    manager_email: true,
                }
            }
        }

        if (all) {
            const clients = await prisma.client.findMany({
                where,
                include,
                orderBy: {
                    razonSocial: 'asc',
                },
            })

            return {
                data: clients,
                pagination: null,
            }
        }

        const skip = (page - 1) * pageSize

        const [clients, total] = await Promise.all([
            prisma.client.findMany({
                where,
                skip,
                take: pageSize,
                include,
                orderBy: {
                    razonSocial: 'asc',
                },
            }),
            prisma.client.count({ where }),
        ])

        return {
            data: clients,
            pagination: {
                page,
                pageSize,
                total,
                totalPages: Math.ceil(total / pageSize),
            },
        }
    },

    async listClients(search, page, pageSize, all = false) {
        return this.searchClients(search, page, pageSize, all)
    },
}