import { ReporteInspeccionService } from '../../service/reporte/inspeccion.service.js'

export const ReporteInspeccionController = {

    async obtenerReporte(req, res) {
        try {
            const { servicioId } = req.params

            const reporte = await ReporteInspeccionService.generar(Number(servicioId))

            res.json({
                ok: true,
                reporte
            })
        } catch (error) {
            console.error(error)
            res.status(500).json({
                ok: false,
                message: 'Error al generar reporte de inspección'
            })
        }
    }

}