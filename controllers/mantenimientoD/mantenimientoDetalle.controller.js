import { MantenimientoDetalleService } from '../../service/mantenimientoD/mantenimientoDetalle.service.js'
import { emitMaintenanceDetailChange } from '../../utils/socket.helper.js'

export const MantenimientoDetalleController = {
    async create(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const usuarioId = req.user.sub
            const data = req.body

            const mantenimiento =
                await MantenimientoDetalleService.crear(servicioExtintorId, data, usuarioId)

            // Emitir evento WebSocket para notificar a otros dispositivos
            if (mantenimiento) {
                emitMaintenanceDetailChange('created', mantenimiento);
            }

            return res.status(201).json({
                message: 'Mantenimiento registrado correctamente',
                data: mantenimiento
            })
        } catch (error) {
            return res.status(400).json({
                message: error.message
            })
        }
    },

    async get(req, res) {
        try {
            const { servicioExtintorId } = req.params

            if (!servicioExtintorId) {
                return res.status(400).json({ message: 'servicioExtintorId es requerido' })
            }

            const mantenimiento = await MantenimientoDetalleService.getByServicioExtintorId(
                Number(servicioExtintorId)
            )

            if (!mantenimiento) {
                return res.status(404).json({ message: 'Mantenimiento no encontrado' })
            }

            return res.json({ data: mantenimiento })
        } catch (error) {
            console.error(error)
            return res.status(500).json({ message: error.message })
        }
    }
}