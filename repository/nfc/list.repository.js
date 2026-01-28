import { prisma } from '../../database/client.mjs';

export const ListRepository = {
    async listAll() {
        return prisma.extintor.findMany({
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            }
        });
    },

    async findByNFC(codigoNFC) {
        return prisma.extintor.findUnique({
            where: { codigoNFC },
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            }
        });
    },

    async findBySerialNumber(searchTerm, sedeId = null) {
        const where = {
            serialNumber: searchTerm
        };
        
        // Si se proporciona sedeId, filtrar también por sede
        if (sedeId !== null && sedeId !== undefined) {
            where.sedeId = Number(sedeId);
        }
        
        return prisma.extintor.findFirst({
            where,
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            }
        });
    },

    async findById(extintorId) {
        return prisma.extintor.findUnique({
            where: { id: Number(extintorId) },
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            }
        });
    },

    async findBySedeId(sedeId) {
        return prisma.extintor.findMany({
            where: {
                sedeId: sedeId,
            },
            orderBy: {
                id: 'asc',
            },
            include: {
                sede: {
                    select: {
                        id: true,
                        name_sede: true,
                    },
                },
            },
        });
    },

    async getBySede(sedeId) {
        return prisma.extintor.findMany({
            where: {
                sedeId: Number(sedeId),
            },
            select: {
                type: true,
                agent: true,
                status: true,
            },
        });
    },

    /**
     * Obtener extintores modificados después de un timestamp
     * Para sincronización incremental
     */
    async findUpdatedSince(since) {
        const sinceDate = since ? new Date(since) : null
        
        const where = sinceDate ? {
            OR: [
                { updatedAt: { gte: sinceDate } },
                { createdAt: { gte: sinceDate } }
            ]
        } : {}

        return prisma.extintor.findMany({
            where,
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            },
            orderBy: {
                id: 'asc'
            }
        })
    },

    async listByExtintorNumber(sedeId = null) {
        const where = {
            OR: [
                {serialNumber: null},
                {serialNumber: ''}
            ]
        };
        
        // Si se proporciona sedeId, filtrar también por sede
        if (sedeId !== null && sedeId !== undefined) {
            where.sedeId = Number(sedeId);
        }
        
        return prisma.extintor.findMany({
            where,
            include: {
                sede: {
                    select: {
                        id: true,
                        name_sede: true,
                    },
                },
            },
            orderBy: {
                id: 'asc'
            }
        })
    },
    
    async updateExtintor(extintorId, data) {
        return prisma.extintor.update({
            where: { id: Number(extintorId) },
            data: {
                ...data,
                updatedAt: new Date(),
            },
            include: {
                usuarioCreador: {
                    select: {
                        id: true,
                        name: true,
                        email: true
                    }
                },
                sede: true
            }
        });
    }
};