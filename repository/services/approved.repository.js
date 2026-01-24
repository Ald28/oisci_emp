import { prisma } from '../../database/client.mjs'

export const ApprovedRepository = {

    async getServiceForReview(serviceId) {
        return prisma.servicio.findUnique({
            where: { id: serviceId },
            include: {
                sede: true,
                user: true,
                servicioExtintores: {
                    include: {
                        extintor: true,
                        mantenimientoDetalle: true,
                        inspeccionDetalle: true
                    }
                }
            }
        })
    },

    async getExtintorHistory(extintorId) {
        return prisma.servicioExtintor.findMany({
            where: { extintorId },
            include: {
                servicio: {
                    select: {
                        id: true,
                        type: true,
                        dateStart: true,
                        statusValid: true
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        })
    },

    async approveService(serviceId, userId, comentario) {
        return prisma.servicio.update({
            where: { id: serviceId },
            data: {
                statusValid: 'APROBADO',
                status: 'FINALIZADO',
                usuarioActualizadorId: userId,
                historic: comentario
            }
        })
    },

    async rejectService(serviceId, userId, comentario) {
        return prisma.servicio.update({
            where: { id: serviceId },
            data: {
                statusValid: 'RECHAZADO',
                usuarioActualizadorId: userId,
                historic: comentario
            }
        })
    },

    async updateExtintorStatus(extintorId, status) {
        return prisma.extintor.update({
            where: { id: extintorId },
            data: { status }
        })
    }

}