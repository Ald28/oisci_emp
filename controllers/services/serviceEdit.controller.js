import { ServiceEditService } from '../../service/services/serviceEdit.service.js'

export const ServiceEditController = {

    async getServiceForEdit(req, res) {
        try {
            const { serviceId } = req.params
            const data = await ServiceEditService.getServiceForEdit(serviceId)
            res.json(data)
        } catch (error) {
            res.status(404).json({ message: error.message })
        }
    },

    async updateInspeccion(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const userId = req.user.id

            const result = await ServiceEditService.editInspeccion(
                servicioExtintorId,
                req.body,
                userId
            )

            res.json(result)
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async updateMantenimiento(req, res) {
        try {
            const { servicioExtintorId } = req.params
            const userId = req.user.id

            const result = await ServiceEditService.editMantenimiento(
                servicioExtintorId,
                req.body,
                userId
            )

            res.json(result)
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async confirmarServicio(req, res) {
        try {
            const { serviceId } = req.params
            const userId = req.user.id

            const result =
                await ServiceEditService.confirmarServicio(serviceId, userId)

            res.json(result)
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    }
}