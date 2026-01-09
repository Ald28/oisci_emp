import { EdiMantenimientoRepository } from '../../repository/mantenimientoD/edit.repository.js'

export const MantenimientoDetalleService = {

    async updateChecklist(servicioExtintorId, payload, usuarioId) {
        // Buscar el MantenimientoDetalle por servicioExtintorId
        const mantenimiento = await EdiMantenimientoRepository.findByServicioExtintorId(
            servicioExtintorId
        )

        if (!mantenimiento) {
            throw new Error('MantenimientoDetalle no encontrado')
        }

        // Actualizar usando el ID del mantenimiento encontrado
        const mantenimientoActualizado = await EdiMantenimientoRepository.update(
            mantenimiento.id,
            payload,
            usuarioId
        )

        return mantenimientoActualizado
    }

}