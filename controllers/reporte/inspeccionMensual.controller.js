// controllers/reporte/inspeccionMensual.controller.js
import PDFDocument from 'pdfkit'
import { ReporteInspeccionMensualService } from '../../service/reporte/inspeccionMensual.service.js'
import path from 'path'
import { toPeruDateTime } from '../../utils/datetime.js'

function drawRow(doc, y, row) {
    const margin = 15
    const pageWidth = doc.page.width
    const usableWidth = pageWidth - margin * 2

    const totalColumns = row.length
    const columnWidth = usableWidth / totalColumns

    let x = margin

    row.forEach((text) => {
        doc.text(String(text ?? ''), x, y, {
            width: columnWidth,
            align: 'center',
        })
        x += columnWidth
    })
}

export const ReporteInspeccionMensualController = {
    async obtener(req, res) {
        const { servicioId } = req.params

        const reporte = await ReporteInspeccionMensualService.generar(Number(servicioId))

        if (!reporte) return res.status(404).json({ message: 'Servicio no encontrado' })

        res.json({ ok: true, reporte })
    },

    async descargar(req, res) {
        const { servicioId } = req.params

        const reporte = await ReporteInspeccionMensualService.generar(Number(servicioId))

        if (!reporte) return res.status(404).json({ message: 'Servicio no encontrado' })

        const doc = new PDFDocument({
            size: 'A4',
            layout: 'landscape',
            margin: 15,
        })

        doc.fontSize(6)

        res.setHeader('Content-Type', 'application/pdf')
        res.setHeader(
            'Content-Disposition',
            `attachment; filename=inspeccion-mensual-${servicioId}.pdf`
        )

        doc.pipe(res)

        // 🔵 LOGO
        const logoPath = path.resolve('uploads/logo.png')
        doc.image(logoPath, 40, 30, { width: 100 })

        doc.fontSize(14)
        doc.text('INSPECCIÓN MENSUAL DE EXTINTORES', 0, 80, { align: 'center' })

        doc.moveDown(2)

        doc.fontSize(5)
        doc.text(`EMPRESA: ${reporte.empresa}`)
        doc.text(`RUC: ${reporte.ruc}`)
        doc.text(`INSTALACIÓN: ${reporte.instalacion}`)
        doc.text(`DIRECCIÓN: ${reporte.direccion}`)
        doc.text(`CIUDAD: ${reporte.ciudad}`)

        // ✅ MES bonito en PDF (Perú)
        doc.text(`MES: ${reporte.mes ?? '-'}`)

        doc.moveDown(2)

        let y = doc.y

        drawRow(doc, y, [
            'Nº', 'Código', 'Capac.', 'Tipo', 'Clase',
            'Presión', 'Marca', 'Modelo', 'Serie',
            'Cilindro', 'Año Fab.', 'P.H.', 'Ubicación',
            'F. Mantto', 'F. Hidro',
            'Num', 'Ubic.', 'Acceso', 'Altura',
            'Pict. Uso', 'Pict. Clase',
            'Manómetro', 'Precinto', 'Cilindro',
            'Agente', 'Colgador', 'Manija',
            'Manguera', 'Tobera', 'Sujetador',
            'Observaciones',
        ])

        y += 20

        const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []

        equipos.forEach((item) => {
            if (y > 750) {
                doc.addPage()
                y = 50
            }

            drawRow(doc, y, [
                item.numero,
                item.codigo,
                item.capacidad,
                item.tipo,
                item.claseRating ?? 'N.I.',
                item.presionEquipo,
                item.marca,
                item.modelo,
                item.numeroSerie,
                item.numeroCilindro,
                item.anioFabricacion,

                // ✅ Fechas bonitas en PDF
                toPeruDateTime(item.ph),

                item.ubicacionEquipo,
                toPeruDateTime(item.fechaVencMantto),
                toPeruDateTime(item.fechaPruebaHidro),

                1,
                item.ubicadoNumeracion,
                item.accesoLibre,
                item.alturaAdecuada,
                item.pictogramaUso,
                item.pictogramaClase,
                item.manometro,
                item.precinto,
                item.cilindroEstado,
                item.indicaAgente,
                item.colgador,
                item.manija,
                item.manguera,
                item.tobera,
                item.sujetador,
                item.observaciones,
            ])

            y += 18
        })

        doc.end()
    },
}
