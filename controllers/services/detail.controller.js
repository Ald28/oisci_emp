import { CertificadoDataService } from "../../service/services/detail.service.js";

export const CertificadoDataController = {
    async getData(req, res) {
        try {
            const { servicioId, tipo } = req.params;

            const result = await CertificadoDataService.execute(servicioId, tipo);

            if (!result.ok) {
                return res.status(result.status).json({
                    status: "error",
                    message: result.message
                });
            }

            return res.status(result.status).json({
                status: "success",
                message: "Datos del certificado obtenidos correctamente",
                data: result.data
            });
        } catch (error) {
            console.error("Error obteniendo data del certificado:", error);

            return res.status(500).json({
                status: "error",
                message: "Error interno del servidor",
                error: error.message
            });
        }
    }
};