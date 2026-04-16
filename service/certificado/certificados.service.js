import { certificadosRepository } from "../../repository/certificado/certificados.repository.js";

const TIPOS_VALIDOS = ["OPER", "BAJA", "HIDRO"];
const EMITIDOS_VALIDOS = ["SI", "NO"];

const parseTipos = (query) => {
  if (query.tipo) {
    const tipo = String(query.tipo).trim().toUpperCase();

    if (!TIPOS_VALIDOS.includes(tipo)) {
      const error = new Error(`Tipo inválido: ${tipo}`);
      error.statusCode = 400;
      throw error;
    }

    return [tipo];
  }

  if (query.tipos) {
    const tipos = String(query.tipos)
      .split(",")
      .map((item) => item.trim().toUpperCase())
      .filter(Boolean);

    const invalidos = tipos.filter((tipo) => !TIPOS_VALIDOS.includes(tipo));

    if (invalidos.length) {
      const error = new Error(`Tipos inválidos: ${invalidos.join(", ")}`);
      error.statusCode = 400;
      throw error;
    }

    return tipos;
  }

  return [...TIPOS_VALIDOS];
};

const parseEmitido = (emitido) => {
  if (!emitido) return undefined;

  const value = String(emitido).trim().toUpperCase();

  if (!EMITIDOS_VALIDOS.includes(value)) {
    const error = new Error(`Emitido inválido: ${value}`);
    error.statusCode = 400;
    throw error;
  }

  return value;
};

const mapDetalle = (detalle, servicioExtintor) => {
  return {
    id: detalle.id,
    estado: detalle.estado,
    checklist: detalle.checklist,
    extintorId: detalle.extintorId,
    createdAt: detalle.createdAt,
    updatedAt: detalle.updatedAt,
    extintor: detalle.extintor,
    servicioExtintor: servicioExtintor
      ? {
          id: servicioExtintor.id,
          codeServ: servicioExtintor.codeServ,
          servicioId: servicioExtintor.servicioId,
          extintorId: servicioExtintor.extintorId,
          estadoInicial: servicioExtintor.estadoInicial,
          estadoFinal: servicioExtintor.estadoFinal,
          completado: servicioExtintor.completado,
          observaciones: servicioExtintor.observaciones,
          createdAt: servicioExtintor.createdAt,
          updatedAt: servicioExtintor.updatedAt,
          mantenimientoDetalle: servicioExtintor.mantenimientoDetalle,
          inspeccionDetalle: servicioExtintor.inspeccionDetalle,
        }
      : null,
  };
};

const mapCertificado = async (certificado) => {
  const servicioExtintores =
    await certificadosRepository.findServicioExtintoresByServicioId(
      certificado.servicioId,
    );

  const servicioExtintorMap = new Map(
    servicioExtintores.map((item) => [item.extintorId, item]),
  );

  return {
    id: certificado.id,
    tipo: certificado.tipo,
    numeroCertificado: certificado.numeroCertificado,
    fechaEmision: certificado.fechaEmision,
    emitido: certificado.emitido,
    frecuencia: certificado.frecuencia,
    archivoPdfUrl: certificado.archivoPdfUrl,
    clientId: certificado.clientId,
    sedeId: certificado.sedeId,
    servicioId: certificado.servicioId,
    aprobadorId: certificado.aprobadorId,
    usuarioCreadorId: certificado.usuarioCreadorId,
    usuarioActualizadorId: certificado.usuarioActualizadorId,
    createdAt: certificado.createdAt,
    updatedAt: certificado.updatedAt,
    detalles: certificado.certificadoDetalles.map((detalle) =>
      mapDetalle(detalle, servicioExtintorMap.get(detalle.extintorId)),
    ),
  };
};

export const certificadosService = {
  async listInformacion(query = {}) {
    const tipos = parseTipos(query);
    const emitido = parseEmitido(query.emitido);

    const certificados = await certificadosRepository.findMany({
      tipos,
      emitido,
      servicioId: query.servicioId,
    });

    const data = await Promise.all(certificados.map(mapCertificado));

    return {
      total: data.length,
      filtros: {
        tipos,
        emitido: emitido || null,
        servicioId: query.servicioId ? Number(query.servicioId) : null,
      },
      data,
    };
  },

  async getInformacionById(id) {
    if (!id || Number.isNaN(Number(id))) {
      const error = new Error("Id inválido");
      error.statusCode = 400;
      throw error;
    }

    const certificado = await certificadosRepository.findById(id);

    if (!certificado) {
      const error = new Error("Certificado no encontrado");
      error.statusCode = 404;
      throw error;
    }

    return mapCertificado(certificado);
  },
};
