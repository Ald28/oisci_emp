import { prisma } from '../../database/client.mjs'

function upsertFotos({ servicioExtintorId, fotos, userId }) {
    return prisma.inspeccionDetalle.upsert({
        where: { servicioExtintorId },
        update: {
            ...fotos,
            usuarioActualizador: { connect: { id: userId } },
        },
        create: {
            ...fotos,
            servicioExtintor: { connect: { id: servicioExtintorId } },
            usuarioCreador: { connect: { id: userId } }
        },
    })
}

function upsertDetalle({ servicioExtintorId, data, userId }) {
    return prisma.inspeccionDetalle.upsert({
        where: { servicioExtintorId },
        update: {
            ...data,
            usuarioActualizador: { connect: { id: userId } },
        },
        create: {
            ...data,
            servicioExtintor: { connect: { id: servicioExtintorId } },
            usuarioCreador: { connect: { id: userId } }
        },
    })
}

export default {
    upsertFotos,
    upsertDetalle,
}