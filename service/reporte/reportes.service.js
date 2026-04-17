import { reportesRepository } from '../../repository/reporte/reportes.repository.js'

const TIPOS_REPORTE_VALIDOS = [
    'INSPECCION',
    'REPORTE_FOTOGRAFICO'
]

const FRECUENCIAS_VALIDAS = [
    'MENSUAL'
]

export const reportesService = {
    async createReporte({ servicioId, tipo, frecuencia, pdfUrl, usuarioCreadorId }) {

        if (!servicioId || isNaN(servicioId)) {
            throw new Error('servicioId es requerido y debe ser numérico')
        }

        if (!tipo) {
            throw new Error('tipo es requerido')
        }

        if (!TIPOS_REPORTE_VALIDOS.includes(tipo)) {
            throw new Error(
                `tipo no válido. Debe ser uno de: ${TIPOS_REPORTE_VALIDOS.join(', ')}`
            )
        }

        if (frecuencia && !FRECUENCIAS_VALIDAS.includes(frecuencia)) {
            throw new Error(
                `frecuencia no válida. Debe ser una de: ${FRECUENCIAS_VALIDAS.join(', ')}`
            )
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
            frecuencia: frecuencia || null,
            archivoPdfUrl: pdfUrl,
            fechaEmision: new Date(),
            emitido: 'SI',
            usuarioCreadorId
        }

        return await reportesRepository.createReporte(data)
    }
}