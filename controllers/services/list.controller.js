import { ListService } from '../../service/services/list.service.js'

export const ListController = {
    async listServicioExtintores(req, res) {
        try {
            const { servicioId } = req.params

            const extintores =
                await ListService.listServicioExtintores(servicioId)

            res.status(200).json({
                data: extintores
            })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async getInProgress(req, res) {
        try {
            const usuarioId = req.user.sub

            const servicios =
                await ListService.getInProgressByUser(usuarioId)

            res.status(200).json({
                data: servicios
            })

        } catch (error) {
            res.status(400).json({ message: error.message })
        }

    }

}