import { ListRepository } from '../../repository/services/list.repository.js'

export const ListService = {

    async listServicioExtintores(servicioId) {
        const servicio = await ListRepository.findById(servicioId)

        if (!servicio) {
            throw new Error('Servicio no encontrado')
        }

        return ListRepository.findServicioExtintores(servicioId)
    }
}