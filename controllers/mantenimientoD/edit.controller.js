import { MantenimientoDetalleService } from '../../service/mantenimientoD/edit.service.js'
import { emitMaintenanceDetailChange } from '../../utils/socket.helper.js'

export const MantenimientoDetalleController = {

    async update(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const usuarioId = req.user.sub

            const mantenimientoActualizado =
                await MantenimientoDetalleService.updateChecklist(
                    servicioExtintorId,
                    req.body,
                    usuarioId
                )

            // Emitir evento WebSocket para notificar a otros dispositivos
            if (mantenimientoActualizado) {
                emitMaintenanceDetailChange('updated', mantenimientoActualizado);
            }

            res.status(200).json({
                message: 'Checklist de mantenimiento actualizado',
                data: mantenimientoActualizado
            })

        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    }

}