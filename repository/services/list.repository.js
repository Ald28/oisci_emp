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
    },

    findInProgressByUser(usuarioCreadorId) {
        return prisma.servicio.findMany({
            where: {
                status: 'EN_PROCESO',
                usuarioCreadorId: Number(usuarioCreadorId)
            },
            include: {
                sede: true,
                user: true
            },
            orderBy: {
                createdAt: 'desc'
            }
        })
    },

    findBySedeId(sedeId) {
        return prisma.servicio.findMany({
            where: {
                sedeId: Number(sedeId)
            },
            include: {
                sede: {
                    select: {
                        id: true,
                        name_sede: true
                    }
                },
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        userCode: true,
                        roleId: true,
                        active: true
                    }
                },
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        userCode: true
                    }
                }
            },
            orderBy: {
                dateStart: 'desc'
            }
        })
    },
}