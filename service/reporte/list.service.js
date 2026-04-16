import { listRepository } from "../../repository/reporte/list.repository.js";

export const listService = {
  async getPdfByReporteId(id) {
    const reporte = await listRepository.getPdfByReporteId(id);

    if (!reporte) {
      throw new Error("Reporte no encontrado");
    }

    return {
      ...reporte,
      archivoPdfUrl: reporte.archivoPdfUrl
        ? `${process.env.API_URL}/reporte/ver/${reporte.id}/preview`
        : null,
    };
  },

  async getPdfByServicioId(servicioId) {
    const reportes = await listRepository.getPdfByServicioId(servicioId);

    if (!reportes || reportes.length === 0) {
      throw new Error("No se encontraron reportes para este servicio");
    }

    return reportes.map((reporte) => ({
      ...reporte,
      archivoPdfUrl: reporte.archivoPdfUrl
        ? `${process.env.API_URL}/reporte/ver/${reporte.id}/preview`
        : null,
    }));
  },
};
