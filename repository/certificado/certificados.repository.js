import { prisma } from "../../database/client.mjs";

const buildWhere = ({ tipos, emitido, servicioId }) => {
  const where = {};

  if (tipos?.length) {
    where.tipo = { in: tipos };
  }

  if (emitido) {
    where.emitido = emitido;
  }

  if (servicioId) {
    where.servicioId = Number(servicioId);
  }

  return where;
};

export const certificadosRepository = {
  async findMany(filters = {}) {
    const where = buildWhere(filters);

    return prisma.certificado.findMany({
      where,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      select: {
        id: true,
        tipo: true,
        numeroCertificado: true,
        fechaEmision: true,
        emitido: true,
        frecuencia: true,
        archivoPdfUrl: true,
        clientId: true,
        sedeId: true,
        servicioId: true,
        aprobadorId: true,
        usuarioCreadorId: true,
        usuarioActualizadorId: true,
        createdAt: true,
        updatedAt: true,
        certificadoDetalles: {
          orderBy: {
            id: "asc",
          },
          select: {
            id: true,
            estado: true,
            checklist: true,
            extintorId: true,
            createdAt: true,
            updatedAt: true,
            extintor: {
              select: {
                id: true,
                codeExtintor: true,
                serialNumberNFC: true,
                type: true,
                capacity: true,
                agent: true,
                cylinderNumber: true,
                location: true,
                status: true,
                historic: true,
                pressure: true,
                brand: true,
                model: true,
                rating: true,
                yearManufacture: true,
                dateHydrostatic: true,
                dateMaintenance: true,
                dateLow: true,
                rechargeDate: true,
                photo: true,
              },
            },
          },
        },
      },
    });
  },

  async findById(id) {
    return prisma.certificado.findUnique({
      where: {
        id: Number(id),
      },
      select: {
        id: true,
        tipo: true,
        numeroCertificado: true,
        fechaEmision: true,
        emitido: true,
        frecuencia: true,
        archivoPdfUrl: true,
        clientId: true,
        sedeId: true,
        servicioId: true,
        aprobadorId: true,
        usuarioCreadorId: true,
        usuarioActualizadorId: true,
        createdAt: true,
        updatedAt: true,
        certificadoDetalles: {
          orderBy: {
            id: "asc",
          },
          select: {
            id: true,
            estado: true,
            checklist: true,
            extintorId: true,
            createdAt: true,
            updatedAt: true,
            extintor: {
              select: {
                id: true,
                codeExtintor: true,
                serialNumberNFC: true,
                type: true,
                capacity: true,
                agent: true,
                cylinderNumber: true,
                location: true,
                status: true,
                historic: true,
                pressure: true,
                brand: true,
                model: true,
                rating: true,
                yearManufacture: true,
                dateHydrostatic: true,
                dateMaintenance: true,
                dateLow: true,
                rechargeDate: true,
                photo: true,
              },
            },
          },
        },
      },
    });
  },

  async findServicioExtintoresByServicioId(servicioId) {
    return prisma.servicioExtintor.findMany({
      where: {
        servicioId: Number(servicioId),
      },
      select: {
        id: true,
        codeServ: true,
        servicioId: true,
        extintorId: true,
        estadoInicial: true,
        estadoFinal: true,
        completado: true,
        observaciones: true,
        createdAt: true,
        updatedAt: true,
        mantenimientoDetalle: {
          select: {
            id: true,
            mantenimiento: true,
            recarga: true,
            agenteCarga: true,
            pruebaHidrostatica: true,
            bajaExtintor: true,
            motivoBaja: true,
            pintura: true,
            recargaCartucho: true,
            cambioPartes: true,
            detallesCambioPartes: true,
            createdAt: true,
            updatedAt: true,
          },
        },
        inspeccionDetalle: {
          select: {
            id: true,
            foto1Url: true,
            foto2Url: true,
            foto3Url: true,
            foto4Url: true,
            ubicacion: true,
            accesibilidad: true,
            instalacion: true,
            instrucciones: true,
            clasificacion: true,
            recarga: true,
            certificacion: true,
            presion: true,
            seguridad: true,
            estado: true,
            carga: true,
            soporte: true,
            activacion: true,
            manguera: true,
            boquilla: true,
            abrazadera: true,
            observaciones: true,
            createdAt: true,
            updatedAt: true,
          },
        },
      },
    });
  },
};
