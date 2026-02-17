import { prisma } from '../../database/client.mjs'
import { ServiceEditRepository } from '../../repository/services/serviceEdit.repository.js'

export const ServiceEditService = {

    async getServiceForEdit(serviceId) {
        const service = await ServiceEditRepository.getServiceForEdit(serviceId)
        if (!service) throw new Error('Servicio no encontrado')
        return service
    },

    async editInspeccion(servicioExtintorId, payload, userId) {

        if (!payload || Object.keys(payload).length === 0) {
            throw new Error('Payload de inspección vacío')
        }

        const servicioExtintor =
            await ServiceEditRepository.getServicioExtintorById(servicioExtintorId)

        if (!servicioExtintor) {
            throw new Error('ServicioExtintor no existe')
        }

        if (servicioExtintor.servicio.type !== 'INSPECCION') {
            throw new Error('El servicio no es de tipo INSPECCION')
        }

        return prisma.$transaction(async (tx) => {
            await ServiceEditRepository.updateInspeccionDetalle(
                tx,
                servicioExtintorId,
                payload,
                userId
            )

            return ServiceEditRepository.completarServicioExtintor(
                tx,
                servicioExtintorId,
                userId
            )
        })
    },

    async editMantenimiento(servicioExtintorId, payload, userId) {

        if (!payload || Object.keys(payload).length === 0) {
            throw new Error('Payload de mantenimiento vacío')
        }

        const servicioExtintor =
            await ServiceEditRepository.getServicioExtintorById(servicioExtintorId)

        if (!servicioExtintor) {
            throw new Error('ServicioExtintor no existe')
        }

        if (servicioExtintor.servicio.type !== 'MANTENIMIENTO') {
            throw new Error('El servicio no es de tipo MANTENIMIENTO')
        }

        return prisma.$transaction(async (tx) => {
            await ServiceEditRepository.updateMantenimientoDetalle(
                tx,
                servicioExtintorId,
                payload,
                userId
            )

            return ServiceEditRepository.completarServicioExtintor(
                tx,
                servicioExtintorId,
                userId
            )
        })
    },

    async confirmarServicio(serviceId, userId) {
        return prisma.$transaction(async (tx) => {

            /*const pendientes =
                await ServiceEditRepository.contarExtintoresPendientes(tx, serviceId)

            if (pendientes > 0) {
                throw new Error('No todos los extintores están completados')
            }*/

            const result =
                await ServiceEditRepository.confirmarServicio(tx, serviceId, userId)

            if (result.count === 0) {
                throw new Error('Servicio no existe o ya fue finalizado')
            }

            return { message: 'Servicio confirmado correctamente' }
        })
    }
}