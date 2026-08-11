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

export const getDataByServiceId = async (serviceId) => {
  return await prisma.extintor.findMany({
    where: {
      serviciosExtintor: {
        some: {
          servicioId: Number(serviceId),
        },
      },
    },
    include: {
      sede: {
        include: {
          client: true,
        },
      },
      serviciosExtintor: {
        where: {
          servicioId: Number(serviceId),
        },
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
  getDataByServiceId,
};
