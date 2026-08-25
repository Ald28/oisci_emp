import { prisma } from '../../database/client.mjs';

export const ListRepository = {
    async listAll(sedeId = null) {
        const where = {};

        if (sedeId !== null && sedeId !== undefined && sedeId !== '') {
            where.sedeId = Number(sedeId);
        }

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
            }
        });
    },

    async findByCodeExtintor(codeExtintor) {
        return prisma.extintor.findFirst({
            where: { codeExtintor },
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

    async findBySearchTerm(searchTerm, sedeId = null) {
        const where = {
            OR: [
                {
                    serialNumberNFC: {
                        equals: searchTerm,
                        mode: 'insensitive'
                    }
                },
                {
                    codeExtintor: {
                        equals: searchTerm,
                        mode: 'insensitive'
                    }
                }
            ]
        };

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
                sedeId: Number(sedeId),
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

    async findUpdatedSince(since) {
        const sinceDate = since ? new Date(since) : null;

        const where = sinceDate ? {
            OR: [
                { updatedAt: { gte: sinceDate } },
                { createdAt: { gte: sinceDate } }
            ]
        } : {};

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
        });
    },

    async listByExtintorNumber({ sedeId = null, page = null, limit = null }) {

        const where = {
            OR: [
                { serialNumberNFC: null },
                { serialNumberNFC: '' }
            ]
        };

        if (sedeId !== null && sedeId !== undefined) {
            where.sedeId = Number(sedeId);
        }

        const queryOptions = {
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
        };

        if (page && limit) {
            const skip = (page - 1) * limit;
            queryOptions.skip = skip;
            queryOptions.take = Number(limit);
        }

        return prisma.extintor.findMany(queryOptions);
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
    },

    async listWithFilters(filters = {}) {
        const conditions = [];

        if (filters.hasCodeExtintor === true) {
            conditions.push(
                { codeExtintor: { not: null } },
                { codeExtintor: { not: "" } }
            );
        }

        if (filters.hasCodeExtintor === false) {
            conditions.push({
                OR: [
                    { codeExtintor: null },
                    { codeExtintor: "" }
                ]
            });
        }

        if (filters.hasSerialNumberNFC === true) {
            conditions.push(
                { serialNumberNFC: { not: null } },
                { serialNumberNFC: { not: "" } }
            );
        }

        if (filters.hasSerialNumberNFC === false) {
            conditions.push({
                OR: [
                    { serialNumberNFC: null },
                    { serialNumberNFC: "" }
                ]
            });
        }

        if (filters.sedeId) {
            conditions.push({ sedeId: filters.sedeId });
        }

        if (filters.clientId) {
            conditions.push({ sede: { clientId: filters.clientId } });
        }

        const where = conditions.length ? { AND: conditions } : {};
        const skip = (filters.page - 1) * filters.limit;

        const [total, extintores] = await prisma.$transaction([
            prisma.extintor.count({ where }),
            prisma.extintor.findMany({
                where,
                skip,
                take: filters.limit,
                orderBy: { id: 'asc' },
                include: {
                    usuarioCreador: {
                        select: {
                            id: true,
                            name: true,
                            email: true
                        }
                    },
                    sede: {
                        include: {
                            client: {
                                select: {
                                    id: true,
                                    razonSocial: true,
                                    active: true
                                }
                            }
                        }
                    }
                }
            })
        ]);

        return { total, extintores };
    },

    async getExtintoresDetalleByServicio(servicioId) {
        return await prisma.servicioExtintor.findMany({
            where: {
                servicioId
            },
            include: {
                extintor: true,
                mantenimientoDetalle: true,
                inspeccionDetalle: true,
                servicio: {
                    include: {
                        sede: {
                            include: {
                                client: true
                            }
                        }
                    }
                }
            },
            orderBy: {
                id: 'asc'
            }
        })
    }

};
