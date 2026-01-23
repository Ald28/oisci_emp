import { ServiceService } from '../../service/services/register.service.js'
import { emitServiceChange, emitServiceExtinguisherChange } from '../../utils/socket.helper.js'

export const ServiceController = {

    async createService(req, res) {
        try {
            const usuarioId = req.user.sub

            const result = await ServiceService.startService(
                req.body,
                usuarioId
            )

            // Emitir evento WebSocket para notificar a otros dispositivos
            if (result.data) {
                emitServiceChange('created', result.data);
            }

            res.status(201).json({
                message: 'Servicio iniciado',
                ...result
            })

        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async addExtintor(req, res) {
        try {
            const usuarioId = req.user.sub
            const { servicioId } = req.params

            const result = await ServiceService.registerExtintor(
                servicioId,
                req.body,
                usuarioId
            )

            // Emitir evento WebSocket para notificar a otros dispositivos
            if (result.data) {
                emitServiceExtinguisherChange('created', result.data);
                // También notificar cambio en el servicio padre
                emitServiceChange('updated', { id: Number(servicioId) });
            }

            res.status(201).json({
                message: 'Extintor agregado al servicio',
                ...result
            })

        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async finalizeService(req, res) {
        try {
            const { servicioId } = req.params
            const usuarioId = req.user.sub

            const ServicivioFinalizado = await ServiceService.finalizeService(
                servicioId,
                usuarioId
            )

            // Emitir evento WebSocket para notificar a otros dispositivos
            if (ServicivioFinalizado) {
                emitServiceChange('finalized', ServicivioFinalizado);
            }

            res.status(200).json({
                message: 'Servicio finalizado correctamente',
                data: ServicivioFinalizado
            })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async updateObservacion(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const { observaciones } = req.body
            const usuarioActualizadorId = req.user.sub

            const result = await ServiceService.registrarObservacion({
                servicioExtintorId,
                observaciones,
                usuarioActualizadorId
            })

            res.json(result)
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    }

}