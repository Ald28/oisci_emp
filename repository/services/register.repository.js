import { prisma } from '../../database/client.mjs'

export const ServiceRepository = {

    async createService({
        type,
        dateStart,
        sedeId,
        userId,
        usuarioCreadorId
    }) {
        return prisma.servicio.create({
            data: {
                type,
                dateStart,
                status: 'EN_PROCESO',
                statusValid: 'APROBADO',

                sede: {
                    connect: { id: sedeId }
                },

                user: {
                    connect: { id: userId }
                },

                usuarioCreador: {
                    connect: { id: usuarioCreadorId }
                }
            }
        })
    },

    async addExtintorToService({
        servicioId,
        extintorId,
        estadoInicial,
        observaciones,
        usuarioCreadorId
    }) {
        return prisma.servicioExtintor.create({
            data: {
                servicio: {
                    connect: { id: servicioId }
                },
                extintor: {
                    connect: { id: extintorId }
                },
                estadoInicial,
                observaciones,
                usuarioCreador: {
                    connect: { id: usuarioCreadorId }
                }
            }
        })
    }

}