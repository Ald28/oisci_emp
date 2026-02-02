import { prisma } from '../../database/client.mjs'

export const ServiceEditRepository = {

    getServiceForEdit(serviceId) {
        return prisma.servicio.findUnique({
            where: { id: Number(serviceId) },
            include: {
                sede: true,
                servicioExtintores: {
                    include: {
                        extintor: true,
                        inspeccionDetalle: true,
                        mantenimientoDetalle: true
                    }
                }
            }
        })
    },

    getServicioExtintorById(servicioExtintorId) {
        return prisma.servicioExtintor.findUnique({
            where: { id: Number(servicioExtintorId) },
            include: {
                servicio: true
            }
        })
    },

    updateInspeccionDetalle(tx, servicioExtintorId, data, userId) {
        return tx.inspeccionDetalle.update({
            where: { servicioExtintorId: Number(servicioExtintorId) },
            data: {
                ...data,
                usuarioActualizadorId: userId
            }
        })
    },

    updateMantenimientoDetalle(tx, servicioExtintorId, data, userId) {
        return tx.mantenimientoDetalle.update({
            where: { servicioExtintorId: Number(servicioExtintorId) },
            data: {
                ...data,
                usuarioActualizadorId: userId
            }
        })
    },

    completarServicioExtintor(tx, servicioExtintorId, userId) {
        return tx.servicioExtintor.update({
            where: { id: Number(servicioExtintorId) },
            data: {
                completado: true,
                usuarioActualizadorId: userId
            }
        })
    },

    contarExtintoresPendientes(tx, serviceId) {
        return tx.servicioExtintor.count({
            where: {
                servicioId: Number(serviceId),
                completado: false
            }
        })
    },

    confirmarServicio(tx, serviceId, userId) {
        return tx.servicio.updateMany({
            where: {
                id: Number(serviceId),
                status: 'PRE_FINALIZADO'
            },
            data: {
                status: 'FINALIZADO',
                statusValid: 'APROBADO',
                usuarioActualizadorId: userId
            }
        })
    }
}