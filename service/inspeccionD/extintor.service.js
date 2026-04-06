import { getExtintoresFull, getData } from "../../repository/inpeccionD/extintor.repository.js";

export const getExtintores = async () => {
  const data = await getExtintoresFull();

  return data.map((ext) => ({
    id: ext.id,
    codeExtintor: ext.codeExtintor,
    photo: ext.photo,

    cliente: ext.sede?.client?.razonSocial,
    sede: ext.sede?.name_sede,

    inspecciones: ext.serviciosExtintor
      .filter((s) => s.inspeccionDetalle && s.servicio?.type === "INSPECCION")
      .map((s) => ({
        fotos: [
          s.inspeccionDetalle.foto1Url,
          s.inspeccionDetalle.foto2Url,
          s.inspeccionDetalle.foto3Url,
          s.inspeccionDetalle.foto4Url,
        ].filter(Boolean),

        observacionesDetalle: s.inspeccionDetalle.observaciones,

        observacionesServicio: s.observaciones,

        fecha: s.servicio?.dateStart,
      })),
  }));
};

export const getExtintoresPDF = async () => {
  const data = await getData();

  return data.map((ext) => ({
    id: ext.id,
    codigo: ext.codeExtintor,
    tipo: ext.type,
    capacidad: ext.capacity,
    foto: ext.photo,

    empresa: ext.sede?.client?.razonSocial,
    sede: ext.sede?.name_sede,

    mantenimientos: ext.serviciosExtintor
      .filter(
        (s) => s.servicio?.type === "MANTENIMIENTO" && s.mantenimientoDetalle,
      )
      .map((s) => ({
        fecha: s.servicio.dateStart,

        checklist: {
          mantenimiento: s.mantenimientoDetalle.mantenimiento,
          recarga: s.mantenimientoDetalle.recarga,
          agenteCarga: s.mantenimientoDetalle.agenteCarga,
          pruebaHidrostatica: s.mantenimientoDetalle.pruebaHidrostatica,
          pintura: s.mantenimientoDetalle.pintura,
          cambioPartes: s.mantenimientoDetalle.cambioPartes,
        },

        observaciones: s.observaciones || null,
      })),

    inspecciones: ext.serviciosExtintor
      .filter((s) => s.servicio?.type === "INSPECCION" && s.inspeccionDetalle)
      .map((s) => ({
        fecha: s.servicio.dateStart,

        checklist: {
          ubicacion: s.inspeccionDetalle.ubicacion,
          accesibilidad: s.inspeccionDetalle.accesibilidad,
          instalacion: s.inspeccionDetalle.instalacion,
          presion: s.inspeccionDetalle.presion,
          manguera: s.inspeccionDetalle.manguera,
          boquilla: s.inspeccionDetalle.boquilla,
        },

        fotos: [
          s.inspeccionDetalle.foto1Url,
          s.inspeccionDetalle.foto2Url,
          s.inspeccionDetalle.foto3Url,
          s.inspeccionDetalle.foto4Url,
        ].filter(Boolean),

        observaciones: s.inspeccionDetalle.observaciones,
      })),
  }));
};

export default {
  getExtintores,
  getExtintoresPDF,
};
