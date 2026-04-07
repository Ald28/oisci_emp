import { reportesRepository } from '../../repository/reporte/reportes.repository.js'

export const reportesService = {
    async createReporte({ servicioId, tipo, pdfUrl, usuarioCreadorId }) {

        if (!servicioId || isNaN(servicioId)) {
            throw new Error('servicioId es requerido y debe ser numérico')
        }

        if (!tipo) {
            throw new Error('tipo es requerido')
        }

        if (!pdfUrl) {
            throw new Error('pdfUrl es requerido')
        }

        try {
            new URL(pdfUrl)
        } catch (error) {
            throw new Error('pdfUrl no es una URL válida')
        }

        if (!pdfUrl.includes('amazonaws.com')) {
            throw new Error('El archivo debe estar alojado en S3')
        }

        const data = {
            servicioId: Number(servicioId),
            tipo,
            archivoPdfUrl: pdfUrl,
            fechaEmision: new Date(),
            emitido: 'SI',
            usuarioCreadorId
        }

        return await reportesRepository.createReporte(data)
    }
}