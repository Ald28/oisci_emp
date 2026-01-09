import { prisma } from '../../database/client.mjs'

export const EdiMantenimientoRepository = {
    update({
        id,
        mantenimiento,
        recarga,
        agenteCarga,
        pruebaHidrostatica,
        bajaExtintor,
        motivoBaja,
        pintura,
        recargaCartucho,
        cambioPartes,
        usuarioActualizadorId
    }) {
        return prisma.mantenimientoDetalle.update({
            where: { id },
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

                usuarioActualizador: {
                    connect: { id: usuarioActualizadorId }
                }
            }
        })
    },
    findServicioExtintorById(servicioExtintorId) {
        return prisma.servicioExtintor.findUnique({
            where: { id: Number(servicioExtintorId) },
            include: { mantenimientoDetalle: true }
        })
    },
}