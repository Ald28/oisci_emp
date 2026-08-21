import { prisma } from '../../database/client.mjs'

export const DeleteClients = {

    softDeleteClient(clientId) {
        return prisma.$transaction(async (tx) => {
            const client = await tx.client.update({
                where: { id: clientId },
                data: { active: false },
            })

            const sedes = await tx.sede.updateMany({
                where: {
                    clientId,
                    active: true,
                },
                data: { active: false },
            })

            return {
                ...client,
                sedesDesactivadas: sedes.count,
            }
        })
    },

    restoreClient(clientId) {
        return prisma.$transaction(async (tx) => {
            const client = await tx.client.update({
                where: { id: clientId },
                data: { active: true },
            })

            const sedes = await tx.sede.updateMany({
                where: {
                    clientId,
                    active: false,
                },
                data: { active: true },
            })

            return {
                ...client,
                sedesActivadas: sedes.count,
            }
        })
    },
}
