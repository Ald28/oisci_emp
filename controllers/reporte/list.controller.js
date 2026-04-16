import { listService } from "../../service/reporte/list.service.js";

export const listController = {
  async getPdfByReporteId(req, res) {
    try {
      const { id } = req.params;

      const data = await listService.getPdfByReporteId(id);

      res.json({
        ok: true,
        data,
      });
    } catch (error) {
      res.status(400).json({
        ok: false,
        message: error.message,
      });
    }
  },

  async getPdfByServicioId(req, res) {
    try {
      const { servicioId } = req.params;

      const data = await listService.getPdfByServicioId(servicioId);

      res.json({
        ok: true,
        data,
      });
    } catch (error) {
      res.status(400).json({
        ok: false,
        message: error.message,
      });
    }
  },
};
