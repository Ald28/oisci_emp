import { prisma } from '../../database/client.mjs'

export const MantenimientoDetalleRepository = {
    findServicioExtintorById(servicioExtintorId) {
        return prisma.servicioExtintor.findUnique({
            where: { id: Number(servicioExtintorId) },
            include: { mantenimientoDetalle: true }
        })
    },

    create({
        servicioExtintorId,
        mantenimiento,
        recarga,
        agenteCarga,
        pruebaHidrostatica,
        bajaExtintor,
        motivoBaja,
        pintura,
        recargaCartucho,
        cambioPartes,
        detallesCambioPartes,
        usuarioCreadorId
    }) {
        return prisma.mantenimientoDetalle.create({
            data: {
                mantenimiento,
                recarga,
                agenteCarga,
                pruebaHidrostatica,
                bajaExtintor,
                motivoBaja,
                pintura,
                recargaCartucho,
                cambioPartes,
                detallesCambioPartes,

                servicioExtintor: {
                    connect: { id: servicioExtintorId }
                },

                usuarioCreador: {
                    connect: { id: usuarioCreadorId }
                }
            }
        })
    },

    completarServicioExtintor(servicioExtintorId, estadoFinal) {
        return prisma.servicioExtintor.update({
            where: { id: Number(servicioExtintorId) },
            data: {
                completado: true,
                estadoFinal
            }
        })
    }
}