import PDFDocument from 'pdfkit'
import axios from 'axios'
import { ReporteInspeccionService } from '../../service/reporte/inspeccion.service.js'
import { toPeruDateTime } from '../../utils/datetime.js'
import { obtenerKeyDesdeS3Url } from '../../service/inspeccionD/storage/keyS3.js'
import { presignPreview } from '../../utils/presignPreview.js'

async function descargarImagenPrivada(urlOrKey) {
    const key = obtenerKeyDesdeS3Url(urlOrKey)
    const signedUrl = await presignPreview(key, 'imagen.jpg')

    const response = await axios.get(signedUrl, {
        responseType: 'arraybuffer',
        timeout: 15000,
    })

    return Buffer.from(response.data)
}

export const ReporteInspeccionController = {

    async obtenerReporte(req, res) {
        try {
            const { servicioId } = req.params

            if (!servicioId) {
                return res.status(400).json({
                    ok: false,
                    message: 'servicioId es requerido',
                })
            }

            const reporte = await ReporteInspeccionService.generar(Number(servicioId))

            if (!reporte) {
                return res.status(404).json({
                    ok: false,
                    message: 'Reporte de inspección no encontrado',
                })
            }
            
            return res.status(200).json({
                ok: true,
                reporte: [reporte],
            })
        } catch (error) {
            console.error(error)
            return res.status(500).json({
                ok: false,
                message: 'Error al generar reporte de inspección',
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

            // DATOS GENERALES
            doc.fontSize(12)
            doc.text(`Cliente: ${reporte.cliente.razonSocial}`)
            doc.text(`RUC: ${reporte.cliente.ruc}`)
            doc.text(`Sede: ${reporte.sede.nombre}`)
            doc.text(`Dirección: ${reporte.sede.direccion}`)
            doc.text(`Ciudad: ${reporte.sede.ciudad}`)
            doc.moveDown()

            doc.text(`Tipo de Servicio: ${reporte.servicio.tipo}`)
            doc.text(`Fecha Inicio: ${reporte.servicio.fechaInicio ?? '-'}`)
            doc.text(`Fecha Fin: ${reporte.servicio.fechaFin ?? '-'}`)
            doc.moveDown()

            doc.fontSize(14).text('EQUIPOS INSPECCIONADOS')
            doc.moveDown()

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []

            for (let index = 0; index < equipos.length; index++) {
                const eq = equipos[index]

                doc.fontSize(12).text(`Equipo ${index + 1}`)
                doc.text(`Código: ${eq.codigo ?? '-'}`)
                doc.text(`Tipo: ${eq.tipo ?? '-'}`)
                doc.text(`Ubicación: ${eq.ubicacion ?? '-'}`)
                doc.text(`Fecha Inspección: ${eq.fechaHora ?? '-'}`)
                doc.moveDown()

                doc.text('Checklist:')
                if (eq.checklist && typeof eq.checklist === 'object') {
                    Object.entries(eq.checklist).forEach(([key, value]) => {
                        doc.text(`- ${key}: ${value ?? '-'}`)
                    })
                } else {
                    doc.text('- Sin checklist')
                }

                doc.moveDown()

                doc.text(`Observaciones: ${eq.observaciones ?? '-'}`)
                doc.moveDown()

                // Fotos
                if (eq.fotos?.foto1Url) {
                    try {
                        const img = await descargarImagenPrivada(eq.fotos.foto1Url)
                        doc.image(img, { fit: [150, 150] })
                        doc.moveDown()
                    } catch (error) {
                        console.error('Error cargando foto1:', error.message)
                        doc.text('No se pudo cargar la foto 1')
                        doc.moveDown()
                    }
                }

                if (eq.fotos?.foto2Url) {
                    try {
                        const img = await descargarImagenPrivada(eq.fotos.foto2Url)
                        doc.image(img, { fit: [150, 150] })
                        doc.moveDown()
                    } catch (error) {
                        console.error('Error cargando foto2:', error.message)
                        doc.text('No se pudo cargar la foto 2')
                        doc.moveDown()
                    }
                }

                if (eq.fotos?.foto3Url) {
                    try {
                        const img = await descargarImagenPrivada(eq.fotos.foto3Url)
                        doc.image(img, { fit: [150, 150] })
                        doc.moveDown()
                    } catch (error) {
                        console.error('Error cargando foto3:', error.message)
                        doc.text('No se pudo cargar la foto 3')
                        doc.moveDown()
                    }
                }

                if (index < equipos.length - 1) {
                    doc.addPage()
                }
            }

            doc.end()
        } catch (error) {
            console.error(error)

            if (!res.headersSent) {
                res.status(500).json({ message: 'Error al generar certificado' })
            }
        }
    },
}