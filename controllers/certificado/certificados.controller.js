import { certificadosService } from "../../service/certificado/certificados.service.js";

export const certificadosController = {
  async listInformacion(req, res, next) {
    try {
      const result = await certificadosService.listInformacion(req.query);

      return res.status(200).json({
        ok: true,
        certificados: result.data,
        total: result.total,
        filtros: result.filtros,
      });
    } catch (error) {
      next(error);
    }
  },

  async getInformacionById(req, res, next) {
    try {
      const { id } = req.params;

      const certificado = await certificadosService.getInformacionById(id);

      return res.status(200).json({
        ok: true,
        certificado,
      });
    } catch (error) {
      next(error);
    }
  },
};
