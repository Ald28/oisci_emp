import { prisma } from "../../database/client.mjs";

export const DeleteExtintores = {
  softDeleteExtintor(id) {
    return prisma.extintor.update({
      where: { id },
      data: { active: false },
    });
  },

  restoreExtintor(id) {
    return prisma.extintor.update({
      where: { id },
      data: { active: true },
    });
  },
};

export default DeleteExtintores;
