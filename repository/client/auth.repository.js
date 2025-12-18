import { prisma } from '../../database/client.mjs'

export const AuthRepository = {
    findUserByEmail(email) {
        return prisma.user.findUnique({
            where: { email },
            include: {
                role: {
                    include: {
                        permissions: {
                            include: {
                                permission: true,
                            },
                        },
                    },
                },
                clients: true,
            },
        })
    },

    saveRefreshToken(data) {
        return prisma.refreshToken.create({ data })
    },
}