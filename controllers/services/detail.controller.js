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
    },

    async getPdf(req, res) {
        try {
            const { servicioId, tipo } = req.params;

            const result = await CertificadoDataService.generatePdf(servicioId, tipo);

            if (!result.ok) {
                return res.status(result.status).json({
                    status: "error",
                    message: result.message
                });
            }

            res.setHeader("Content-Type", "application/pdf");
            res.setHeader("Content-Disposition", `inline; filename="${result.fileName}"`);

            return res.status(200).send(result.pdfBuffer);
        } catch (error) {
            console.error("Error generando PDF del certificado:", error);

            return res.status(500).json({
                status: "error",
                message: "Error interno del servidor",
                error: error.message
            });
        }
    }
};