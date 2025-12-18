import { prisma } from '../../database/client.mjs'

export const EditClients = {
    async updateClientAndUser(clientId, clientData, userData) {
        return prisma.$transaction(async (tx) => {

            const clientResult = await tx.client.updateMany({
                where: { id: clientId, active: true },
                data: clientData,
            })

            if (clientResult.count === 0) {
                throw new Error('Cliente no existe o está inactivo')
            }

            const client = await tx.client.findUnique({
                where: { id: clientId },
            })

            const userResult = await tx.user.updateMany({
                where: { id: client.userId, active: true },
                data: userData,
            })

            if (userResult.count === 0) {
                throw new Error('Usuario no existe o está inactivo')
            }

            const user = await tx.user.findUnique({
                where: { id: client.userId },
            })

            return { client, user }
        })
    },
}
