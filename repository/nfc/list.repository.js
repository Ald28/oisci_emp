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

    async findByCodeOrSerial(searchTerm) {
        return prisma.extintor.findFirst({
            where: {
                OR: [
                    { codeNFC: searchTerm },
                    { serialNumber: searchTerm }
                ]
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