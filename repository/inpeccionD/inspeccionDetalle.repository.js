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

function upsertDetalle({ servicioExtintorId, data, userId, foto1Url }) {
    return prisma.$transaction(async (tx) => {

        const inspeccion = await tx.inspeccionDetalle.upsert({
            where: { servicioExtintorId },
            update: {
                ...data,
                usuarioActualizador: { connect: { id: userId } },
            },
            create: {
                ...data,
                servicioExtintor: { connect: { id: servicioExtintorId } },
                usuarioCreador: { connect: { id: userId } },
            },
        })

        if (foto1Url) {
            await tx.extintor.update({
                where: {
                    id: (
                        await tx.servicioExtintor.findUnique({
                            where: { id: servicioExtintorId },
                            select: { extintorId: true },
                        })
                    ).extintorId,
                },
                data: {
                    photo: foto1Url,
                },
            })
        }

        return inspeccion
    })
}

function findByServicioExtintorId(servicioExtintorId) {
    return prisma.inspeccionDetalle.findUnique({
        where: { servicioExtintorId: Number(servicioExtintorId) },
    })
}

export default {
    upsertFotos,
    upsertDetalle,
    findByServicioExtintorId,
}