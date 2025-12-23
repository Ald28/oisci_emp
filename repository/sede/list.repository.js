import { prisma } from '../../database/client.mjs';

export const ListRepository = {
    async listAll() {
        return prisma.sede.findMany();
    },

    async findById(id) {
        return prisma.sede.findUnique({
            where: { id },
        });
    },

    async searchSedeByClient(id){
        return prisma.sede.findUnique({
            where: { id },
        });
    }
};