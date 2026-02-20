import { prisma } from "../../database/client.mjs";

export const EditNFCRepository = {
    async editExtintor(id, data) {
        return await prisma.extintor.update({
            where: { id: Number(id) },
            data: data,
        });
    },
};