import { ApprovedService } from '../../service/services/approved.service.js'

export const ApprovedController = {

    async getReview(req, res) {
        try {
            const { serviceId } = req.params
            const data = await ApprovedService.getServiceReview(Number(serviceId))
            res.json(data)
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async approve(req, res) {
        try {
            const { serviceId } = req.params
            const { comentario } = req.body
            const userId = req.user.id

            const result = await ApprovedService.approveService(
                Number(serviceId),
                userId,
                comentario
            )

            res.json({ message: 'Servicio aprobado', result })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async reject(req, res) {
        try {
            const { serviceId } = req.params
            const { comentario } = req.body
            const userId = req.user.id

            const result = await ApprovedService.rejectService(
                Number(serviceId),
                userId,
                comentario
            )

            res.json({ message: 'Servicio rechazado', result })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    }

}