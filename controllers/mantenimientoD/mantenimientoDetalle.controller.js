import { MantenimientoDetalleService } from '../../service/mantenimientoD/mantenimientoDetalle.service.js'

export const MantenimientoDetalleController = {
    async create(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const usuarioId = req.user.sub
            const data = req.body

            const mantenimiento =
                await MantenimientoDetalleService.crear(servicioExtintorId, data, usuarioId)

            return res.status(201).json({
                message: 'Mantenimiento registrado correctamente',
                data: mantenimiento
            })
        } catch (error) {
            return res.status(400).json({
                message: error.message
            })
        }
    }
}