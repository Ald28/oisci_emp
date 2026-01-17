import { ListRepository } from '../../repository/services/list.repository.js'

export const ListService = {

    async listServicioExtintores(servicioId) {
        const servicio = await ListRepository.findById(servicioId)

        if (!servicio) {
            throw new Error('Servicio no encontrado')
        }

        return ListRepository.findServicioExtintores(servicioId)
    },

    async getInProgressByUser(usuarioId) {
        return ListRepository.findInProgressByUser(usuarioId)
    },

    async getById(servicioId) {
        return ListRepository.findById(servicioId)
    }

}