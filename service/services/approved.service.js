import { ApprovedRepository } from '../../repository/services/approved.repository.js'

export const ApprovedService = {

    async getServiceReview(serviceId) {
        const service = await ApprovedRepository.getServiceForReview(serviceId)

        if (!service) {
            throw new Error('Servicio no encontrado')
        }

        for (const se of service.servicioExtintores) {
            se.extintor.historial = await ApprovedRepository.getExtintorHistory(se.extintorId)
        }

        return service
    },

    async approveService(serviceId, userId, comentario) {
        const service = await ApprovedRepository.getServiceForReview(serviceId)

        if (!service) {
            throw new Error('Servicio no encontrado')
        }

        for (const se of service.servicioExtintores) {
            if (se.estadoFinal) {
                await ApprovedRepository.updateExtintorStatus(
                    se.extintorId,
                    se.estadoFinal
                )
            }
        }

        return ApprovedRepository.approveService(serviceId, userId, comentario)
    },

    async rejectService(serviceId, userId, comentario) {
        if (!comentario || comentario.trim() === '') {
            throw new Error('El comentario es obligatorio para rechazar')
        }

        return ApprovedRepository.rejectService(serviceId, userId, comentario)
    }

}