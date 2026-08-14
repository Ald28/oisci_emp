import { prisma } from "../../database/client.mjs";

export const DeleteExtintores = {
  softDeleteExtintor(id) {
    return prisma.extintor.update({
      where: { id },
      data: { historic: 1 },
    });
  },

  restoreExtintor(id) {
    return prisma.extintor.update({
      where: { id },
      data: { historic: 0 },
    });
  },
};

export default DeleteExtintores;
