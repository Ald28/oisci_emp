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

        const servicioExtintor = await ServiceRepository.addExtintorToService({
            servicioId: Number(servicioId),
            extintorId: data.extintorId,
            estadoInicial: data.estadoInicial,
            observaciones: data.observaciones,
            usuarioCreadorId: usuarioId
        })

        return {
            servicioExtintorId: servicioExtintor.id
        }
    }

}