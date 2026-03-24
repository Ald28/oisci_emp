import { CertificadoDataService } from "../../service/inspeccionD/detail.service.js";

export const CertificadoDataController = {
    async getData(req, res) {
        try {
            const { servicioId } = req.params;

            const result = await CertificadoDataService.execute(servicioId);

            if (!result.ok) {
                return res.status(result.status).json({
                    status: "error",
                    message: result.message
                });
            }

            return res.status(result.status).json({
                status: "success",
                message: "Datos del reporte de inspección obtenidos correctamente",
                data: result.data
            });
        } catch (error) {
            console.error("Error obteniendo data del reporte de inspección:", error);

            return res.status(500).json({
                status: "error",
                message: "Error interno del servidor",
                error: error.message
            });
        }
    },

    async getPdf(req, res) {
        try {
            const { servicioId } = req.params;

            const result = await CertificadoDataService.generatePdf(servicioId);

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
            console.error("Error generando PDF del reporte de inspección:", error);

            return res.status(500).json({
                status: "error",
                message: "Error interno del servidor",
                error: error.message
            });
        }
    }
};