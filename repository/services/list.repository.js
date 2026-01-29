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

    async getBySedeAndYear(sedeId, year) {
        const start = new Date(`${year}-01-01`)
        const end = new Date(`${year}-12-31T23:59:59`)

        return prisma.servicio.findMany({
            where: {
                sedeId: Number(sedeId),
                dateStart: {
                    gte: start,
                    lte: end,
                },
            },
            include: {
                servicioExtintores: {
                    include: {
                        mantenimientoDetalle: true,
                        extintor: {
                            select: { status: true }
                        }
                    }
                }
            }
        })
    },

    /**
     * Obtener TODOS los servicios con todas sus relaciones anidadas
     * Para sincronización inicial completa
     */
    findAllWithDetails() {
        return prisma.servicio.findMany({
            include: {
                sede: {
                    select: {
                        id: true,
                        name_sede: true
                    }
                },
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                servicioExtintores: {
                    include: {
                        mantenimientoDetalle: true,
                        inspeccionDetalle: true
                    },
                    orderBy: {
                        createdAt: 'asc'
                    }
                }
            },
            orderBy: {
                dateStart: 'desc'
            }
        })
    },

    /**
     * Obtener servicios modificados después de un timestamp
     * Para sincronización incremental
     */
    findUpdatedSince(since) {
        const sinceDate = since ? new Date(since) : null
        
        const where = sinceDate ? {
            OR: [
                { updatedAt: { gte: sinceDate } },
                { createdAt: { gte: sinceDate } },
                // También incluir servicios con servicioExtintores modificados
                {
                    servicioExtintores: {
                        some: {
                            OR: [
                                { updatedAt: { gte: sinceDate } },
                                { createdAt: { gte: sinceDate } },
                                // Para mantenimientoDetalle e inspeccionDetalle,
                                // incluimos servicios que tienen estos detalles si el servicioExtintor fue modificado
                                {
                                    AND: [
                                        { mantenimientoDetalle: { isNot: null } },
                                        { updatedAt: { gte: sinceDate } }
                                    ]
                                },
                                {
                                    AND: [
                                        { inspeccionDetalle: { isNot: null } },
                                        { updatedAt: { gte: sinceDate } }
                                    ]
                                }
                            ]
                        }
                    }
                }
            ]
        } : {}

        return prisma.servicio.findMany({
            where,
            include: {
                sede: {
                    select: {
                        id: true,
                        name_sede: true
                    }
                },
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                servicioExtintores: {
                    include: {
                        mantenimientoDetalle: true,
                        inspeccionDetalle: true
                    },
                    orderBy: {
                        createdAt: 'asc'
                    }
                }
            },
            orderBy: {
                dateStart: 'desc'
            }
        })
    }
}