import { MantenimientoDetalleRepository } from '../../repository/mantenimientoD/mantenimientoDetalle.repository.js'

export const MantenimientoDetalleService = {
    async crear(servicioExtintorId, payload, usuarioId) {
        const servicioExtintor =
            await MantenimientoDetalleRepository.findServicioExtintorById(servicioExtintorId)

        if (!servicioExtintor) {
            throw new Error('ServicioExtintor no encontrado')
        }

        if (servicioExtintor.mantenimientoDetalle) {
            throw new Error('Este extintor ya tiene mantenimiento registrado')
        }

        const mantenimiento = await MantenimientoDetalleRepository.create({
            servicioExtintorId: Number(servicioExtintorId),
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
            usuarioCreadorId: usuarioId
        })

        await MantenimientoDetalleRepository.completarServicioExtintor(
            servicioExtintorId,
            payload.estadoFinal
        )

        const fechaMantenimiento = new Date().toISOString()

        await MantenimientoDetalleRepository.updateExtintorRechargeDateByServicioExtintor(
            servicioExtintorId,
            fechaMantenimiento
        )

        return mantenimiento
    },

    async getByServicioExtintorId(servicioExtintorId) {
        return MantenimientoDetalleRepository.findByServicioExtintorId(servicioExtintorId)
    }
}