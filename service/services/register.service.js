import { ServiceRepository } from '../../repository/services/register.repository.js'

export const ServiceService = {

    async startService(data, usuarioId) {

        if (!data.type || !data.sedeId || !data.userId) {
            throw new Error('Datos incompletos para crear el servicio')
        }

        const servicio = await ServiceRepository.createService({
            type: data.type,
            dateStart: new Date(),
            sedeId: data.sedeId,
            userId: data.userId,
            usuarioCreadorId: usuarioId
        })

        return {
            servicioId: servicio.id
        }
    },

    async registerExtintor(servicioId, data, usuarioId) {

        if (!data.extintorId) {
            throw new Error('extintorId es obligatorio')
        }

        try {
            const servicioExtintor = await ServiceRepository.addExtintorToService({
                codeServ: `SERV-${Date.now()}`,
                servicioId: Number(servicioId),
                extintorId: data.extintorId,
                estadoInicial: data.estadoInicial,
                observaciones: data.observaciones,
                usuarioCreadorId: usuarioId
            })

            return {
                servicioExtintorId: servicioExtintor.id
            }
        } catch (error) {
            // Manejar error de Prisma cuando el extintor ya está agregado
            if (error.code === 'P2002' || 
                error.message?.includes('Unique constraint') ||
                error.message?.includes('duplicate') ||
                error.message?.includes('ya existe')) {
                throw new Error('Este extintor ya está agregado al servicio')
            }
            throw error
        }
    },

    async finalizeService(servicioId, usuarioId) {
        const servicio = await ServiceRepository.findById(servicioId)

        if (!servicio) {
            throw new Error('Servicio no encontrado')
        }

        if (servicio.status === 'PRE_FINALIZADO') {
            throw new Error('El servicio ya está PRE_FINALIZADO')
        }

        const servicioFinalizado = await ServiceRepository.finalizeService(
            servicioId, usuarioId
        )

        return servicioFinalizado
    },

    async registrarObservacion(data) {
        if (!data.observaciones || data.observaciones.trim() === '') {
            throw new Error('La observación es obligatoria')
        }

        return ServiceRepository.updateObservacion(data)
    }

}