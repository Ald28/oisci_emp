import { prisma } from '../../database/client.mjs'

export const ListRepository = {

    findById(servicioId) {
        return prisma.servicio.findUnique({
            where: { id: Number(servicioId) }
        })
    },

    findServicioExtintores(servicioId) {
        return prisma.servicioExtintor.findMany({
            where: {
                servicioId: Number(servicioId)
            },
            include: {
                extintor: true,
                mantenimientoDetalle: true
            },
            orderBy: {
                createdAt: 'asc'
            }
        })
    }
}