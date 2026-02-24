import PDFDocument from 'pdfkit'
import axios from 'axios'
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
    },

    async descargarCertificado(req, res) {
        try {
            const { servicioId } = req.params

            const reporte = await ReporteInspeccionService.generar(Number(servicioId))

            if (!reporte) {
                return res.status(404).json({ message: 'Servicio no encontrado' })
            }

            const doc = new PDFDocument({ margin: 50 })

            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader(
                'Content-Disposition',
                `attachment; filename=certificado-${servicioId}.pdf`
            )

            doc.pipe(res)

            doc.fontSize(18).text('CERTIFICADO DE INSPECCIÓN', { align: 'center' })
            doc.moveDown()

            // 🔹 DATOS GENERALES
            doc.fontSize(12)
            doc.text(`Cliente: ${reporte.cliente.razonSocial}`)
            doc.text(`RUC: ${reporte.cliente.ruc}`)
            doc.text(`Sede: ${reporte.sede.nombre}`)
            doc.text(`Dirección: ${reporte.sede.direccion}`)
            doc.text(`Ciudad: ${reporte.sede.ciudad}`)
            doc.moveDown()

            doc.text(`Tipo de Servicio: ${reporte.servicio.tipo}`)
            doc.text(`Fecha Inicio: ${new Date(reporte.servicio.fechaInicio).toLocaleString()}`)
            doc.text(`Fecha Fin: ${new Date(reporte.servicio.fechaFin).toLocaleString()}`)
            doc.moveDown()

            doc.fontSize(14).text('EQUIPOS INSPECCIONADOS')
            doc.moveDown()

            for (const [index, eq] of reporte.equipos.entries()) {

                doc.fontSize(12).text(`Equipo ${index + 1}`)
                doc.text(`Código: ${eq.codigo}`)
                doc.text(`Tipo: ${eq.tipo}`)
                doc.text(`Ubicación: ${eq.ubicacion}`)
                doc.text(`Fecha Inspección: ${new Date(eq.fechaHora).toLocaleString()}`)
                doc.moveDown()

                doc.text('Checklist:')
                Object.entries(eq.checklist).forEach(([key, value]) => {
                    doc.text(`- ${key}: ${value}`)
                })

                doc.moveDown()

                doc.text(`Observaciones: ${eq.observaciones ?? '-'}`)
                doc.moveDown()

                if (eq.fotos?.foto1Url) {
                    const img = await axios.get(eq.fotos.foto1Url, {
                        responseType: 'arraybuffer'
                    })
                    doc.image(img.data, { fit: [150, 150] })
                    doc.moveDown()
                }

                if (eq.fotos?.foto2Url) {
                    const img = await axios.get(eq.fotos.foto2Url, {
                        responseType: 'arraybuffer'
                    })
                    doc.image(img.data, { fit: [150, 150] })
                    doc.moveDown()
                }

                if (eq.fotos?.foto3Url) {
                    const img = await axios.get(eq.fotos.foto3Url, {
                        responseType: 'arraybuffer'
                    })
                    doc.image(img.data, { fit: [150, 150] })
                    doc.moveDown()
                }

                doc.addPage()
            }

            doc.end()

        } catch (error) {
            console.error(error)

            if (!res.headersSent) {
                res.status(500).json({ message: 'Error al generar certificado' })
            }
        }
    }

}