import { ServiceService } from '../../service/services/register.service.js'

export const ServiceController = {

    async createService(req, res) {
        try {
            const usuarioId = req.user.sub

            const result = await ServiceService.startService(
                req.body,
                usuarioId
            )

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

            res.status(200).json({
                message: 'Servicio finalizado correctamente',
                data: ServicivioFinalizado
            })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    }

}