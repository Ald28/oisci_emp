import { reportesService } from '../../service/reporte/reportes.service.js'

export const reportesController = {
    async createReporte(req, res) {
        try {
            const { servicioId, tipo, frecuencia, pdfUrl } = req.body

            const usuarioCreadorId = req.user?.id || 1

            const reporte = await reportesService.createReporte({
                servicioId,
                tipo,
                frecuencia,
                pdfUrl,
                usuarioCreadorId
            })

            return res.status(201).json({
                success: true,
                message: 'Reporte creado correctamente',
                data: reporte
            })

        } catch (error) {
            return res.status(400).json({
                success: false,
                message: error.message
            })
        }
    }
}