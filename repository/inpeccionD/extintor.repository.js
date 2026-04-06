import { prisma } from "../../database/client.mjs";

export const getExtintoresFull = async () => {
  return await prisma.extintor.findMany({
    include: {
      sede: {
        include: {
          client: true,
        },
      },
      serviciosExtintor: {
        include: {
          servicio: true,
          inspeccionDetalle: true,
        },
      },
    },
  });
};

export const getData = async () => {
  return await prisma.extintor.findMany({
    include: {
      sede: {
        include: {
          client: true,
        },
      },
      serviciosExtintor: {
        include: {
          servicio: true,
          mantenimientoDetalle: true,
          inspeccionDetalle: true,
        },
      },
    },
  });
};

export default {
  getExtintoresFull,
  getData,
};
