import { prisma } from '../../database/client.mjs';

export const DeleteRepository = {
    softDeleteSede(id) {
        return prisma.sede.update({
            where: { id },
            data: { active: false },
        })
    },

    restoreSede(id) {
        return prisma.sede.update({
            where: { id },
            data: { active: true },
        })
    },
}