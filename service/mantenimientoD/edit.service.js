import { EdiMantenimientoRepository } from '../../repository/mantenimientoD/edit.repository.js'

export const MantenimientoDetalleService = {

    async updateChecklist(servicioExtintorId, data, usuarioId) {

        const servicioExtintor =
            await EdiMantenimientoRepository.findServicioExtintorById(
                servicioExtintorId
            )

        if (!servicioExtintor) {
            throw new Error('ServicioExtintor no encontrado')
        }

        if (!servicioExtintor.mantenimientoDetalle) {
            throw new Error('El checklist de mantenimiento no existe')
        }

        const mantenimientoActualizado =
            await EdiMantenimientoRepository.update({
                id: servicioExtintor.mantenimientoDetalle.id,
                ...data,
                usuarioActualizadorId: usuarioId
            })

        return mantenimientoActualizado
    }

}