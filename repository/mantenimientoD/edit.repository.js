import { prisma } from '../../database/client.mjs'

export const EdiMantenimientoRepository = {
    update(mantenimientoDetalleId, payload, usuarioActualizadorId) {
        return prisma.mantenimientoDetalle.update({
            where: { id: Number(mantenimientoDetalleId) },
            data: {
                mantenimiento: payload.mantenimiento ?? false,
                recarga: payload.recarga ?? false,
                agenteCarga: payload.agenteCarga,
                pruebaHidrostatica: payload.pruebaHidrostatica ?? false,
                bajaExtintor: payload.bajaExtintor ?? false,
                motivoBaja: payload.motivoBaja,
                pintura: payload.pintura ?? false,
                recargaCartucho: payload.recargaCartucho ?? false,
                cambioPartes: payload.cambioPartes ?? false,
                detallesCambioPartes: payload.detallesCambioPartes,
                usuarioActualizador: {
                    connect: { id: usuarioActualizadorId }
                }
            }
        })
    },

    findByServicioExtintorId(servicioExtintorId) {
        return prisma.mantenimientoDetalle.findUnique({
            where: { servicioExtintorId: Number(servicioExtintorId) }
        })
    }
}