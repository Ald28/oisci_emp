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
        codeServ,
        servicioId,
        extintorId,
        estadoInicial,
        observaciones,
        usuarioCreadorId
    }) {
        return prisma.servicioExtintor.create({
            data: {
                codeServ,
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
    },

    findById(servicioId) {
        return prisma.servicio.findUnique({
            where: { id: Number(servicioId) }
        })
    },

    finalizeService(servicioId, usuarioId) {
        return prisma.servicio.update({
            where: { id: Number(servicioId) },
            data: {
                status: 'PRE_FINALIZADO',
                dateEnd: new Date(),
                usuarioActualizador: {
                    connect: { id: usuarioId }
                }
            }
        })
    },

    updateObservacion({
        servicioExtintorId,
        observaciones,
        usuarioActualizadorId
    }) {
        return prisma.servicioExtintor.update({
            where: {
                id: Number(servicioExtintorId)
            },
            data: {
                observaciones,
                usuarioActualizador: {
                    connect: { id: usuarioActualizadorId }
                }
            }
        })
    }

}