import { prisma } from "../../database/client.mjs";

export const DeleteExtintores = {
  softDeleteExtintor(id) {
    return prisma.extintor.update({
      where: { id },
      data: { historic: 1 },
    });
  },

  softDeleteManyExtintores(ids) {
    return prisma.$transaction(async (tx) => {
      const existing = await tx.extintor.findMany({
        where: { id: { in: ids } },
        select: { id: true, historic: true },
      });

      const existingIds = new Set(existing.map((extintor) => extintor.id));
      const idsEliminados = existing
        .filter((extintor) => extintor.historic !== 1)
        .map((extintor) => extintor.id);
      const idsYaEliminados = existing
        .filter((extintor) => extintor.historic === 1)
        .map((extintor) => extintor.id);
      const idsNoEncontrados = ids.filter((id) => !existingIds.has(id));

      if (idsEliminados.length) {
        await tx.extintor.updateMany({
          where: { id: { in: idsEliminados } },
          data: { historic: 1 },
        });
      }

      return {
        solicitados: ids.length,
        eliminados: idsEliminados.length,
        idsEliminados,
        idsYaEliminados,
        idsNoEncontrados,
      };
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
