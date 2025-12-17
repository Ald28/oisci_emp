import { prisma } from '../database/client.mjs'

export const DeleteClients = {

    softDeleteClient(clientId) {
        return prisma.client.update({
            where: { id: clientId },
            data: { active: false },
        })
    },

    restoreClient(clientId) {
        return prisma.client.update({
            where: { id: clientId },
            data: { active: true },
        })
    },
}