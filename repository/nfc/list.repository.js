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

    async findById(codigoNFC) {
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

    async findBySerialNumber(searchTerm) {
        return prisma.extintor.findFirst({
            where: {
                serialNumber: searchTerm
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