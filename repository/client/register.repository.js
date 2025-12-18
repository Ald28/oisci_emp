import { prisma } from '../../database/client.mjs'

export const RegisterRepository = {
    createUser(data) {
        return prisma.user.create({ data })
    },

    findUserByEmail(email) {
        return prisma.user.findUnique({
            where: { email },
            include: {
                role: true,
                clients: true,
            },
        })
    },

    assignRoleToUser(userId, roleId) {
        return prisma.user.update({
            where: { id: userId },
            data: { roleId },
        })
    },

    createClient(data) {
        return prisma.client.create({ data })
    },
}