import { prisma } from "../../database/client.mjs";

export const listRepository = {
  async getPdfByReporteId(id) {
    return await prisma.reporte.findUnique({
      where: { id: Number(id) },
      select: {
        id: true,
        servicioId: true,
        archivoPdfUrl: true,
      },
    });
  },

  async getPdfByServicioId(servicioId) {
    return await prisma.reporte.findMany({
      where: { servicioId: Number(servicioId) },
      select: {
        id: true,
        servicioId: true,
        tipo: true,
        fechaEmision: true,
        emitido: true,
        archivoPdfUrl: true,
        createdAt: true,
      },
      orderBy: {
        id: "desc",
      },
    });
  },
};
