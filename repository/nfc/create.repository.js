import { prisma } from "../../database/client.mjs";

export const CreateNFCRepository = {
    async create(data) {
        return prisma.extintor.create({
            data,
            include: {
                usuarioCreador: true,
                sede: true
            }
        });
    }
};