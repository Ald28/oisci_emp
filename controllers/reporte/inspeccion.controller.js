import PDFDocument from 'pdfkit'
import axios from 'axios'
import path from 'path'
import { ReporteInspeccionService } from '../../service/reporte/inspeccion.service.js'
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

function toMonthYear(value) {
    if (!value) return '-'
    const dt = new Date(value)
    if (Number.isNaN(dt.getTime())) return '-'
    return dt.toLocaleDateString('es-PE', { month: 'short', year: 'numeric' }).toUpperCase()
}

function clasificarEquiposServicio(equipos) {
    const oper = equipos.filter((equipo) => {
        const m = equipo.mantenimientoDetalle || {}
        return Boolean(
            m.mantenimiento
            || m.recarga
            || m.pintura
            || m.cambioPartes
            || equipo.estadoFinal === 'OPERATIVO'
        )
    })

    const hidro = equipos.filter((equipo) => Boolean(equipo.mantenimientoDetalle?.pruebaHidrostatica))
    const baja = equipos.filter((equipo) => Boolean(equipo.mantenimientoDetalle?.bajaExtintor))

    return { oper, hidro, baja }
}

function dibujarCabeceraPagina(doc, tituloGeneral, tituloSeccion, conteo, numeroPaginaSeccion, totalPaginasSeccion) {
    const logoPath = path.resolve('uploads/logo.png')
    try {
        doc.image(logoPath, doc.page.margins.left, 18, { width: 62 })
        doc.image(logoPath, doc.page.width - doc.page.margins.right - 62, 18, { width: 62 })
    } catch (err) {
        // ignore missing logo
    }

    doc.font('Helvetica-Bold').fontSize(14).text(tituloGeneral, 0, 42, { align: 'center' })
    doc.font('Helvetica-Bold').fontSize(12).text(tituloSeccion, 0, 62, { align: 'center' })
    doc.font('Helvetica').fontSize(9).text(`Extintores correspondientes: ${conteo}`, 0, 80, { align: 'center' })
    doc.font('Helvetica').fontSize(8).text(
        `Página sección: ${numeroPaginaSeccion}/${totalPaginasSeccion}`,
        0,
        94,
        { align: 'center' },
    )
}

function dibujarTablaSeccion(doc, equiposPagina, tipoSeccion, offsetIndice) {
    const startX = doc.page.margins.left
    let y = 118
    const rowH = 20
    const widths = tipoSeccion === 'HIDRO'
        ? [24, 50, 50, 58, 62, 58, 48, 48, 58, 66]
        : tipoSeccion === 'BAJA'
            ? [24, 50, 50, 58, 62, 58, 56, 62, 74]
            : [24, 50, 50, 58, 62, 58, 56, 48, 58, 66]

    const headers = tipoSeccion === 'HIDRO'
        ? ['N°', 'COD.', 'CAP.', 'AGENTE', 'MARCA', 'MODELO', 'N° SERIE', 'P.H.', 'PRÓX. P.H.', 'RESULTADO']
        : tipoSeccion === 'BAJA'
            ? ['N°', 'COD.', 'CAP.', 'AGENTE', 'MARCA', 'MODELO', 'N° SERIE', 'FECHA BAJA', 'ESTADO']
            : ['N°', 'COD.', 'CAP.', 'AGENTE', 'MARCA', 'MODELO', 'N° SERIE', 'AÑO', 'P.H.', 'PROX. MANTTO.']

    const drawCell = (x, yy, w, h, text, bold = false) => {
        doc.rect(x, yy, w, h).stroke()
        doc.font(bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(8)
        doc.text(text, x + 2, yy + 5, { width: w - 4, align: 'center' })
    }

    let x = startX
    for (let i = 0; i < headers.length; i++) {
        drawCell(x, y, widths[i], rowH, headers[i], true)
        x += widths[i]
    }
    y += rowH

    if (!equiposPagina.length) {
        doc.font('Helvetica').fontSize(10).text('Sin extintores en esta sección.', startX, y + 16)
        return y + 40
    }

    equiposPagina.forEach((eq, index) => {
        const posicion = offsetIndice + index + 1
        const row = tipoSeccion === 'HIDRO'
            ? [
                String(posicion),
                eq.codigo || '-',
                eq.capacidad || '-',
                eq.agente || '-',
                eq.marca || '-',
                eq.modelo || '-',
                eq.nSerie || '-',
                toMonthYear(eq.fechaHidrostatica),
                eq.fechaHidrostatica ? String(new Date(eq.fechaHidrostatica).getFullYear() + 5) : '-',
                eq.estadoFinal === 'OPERATIVO' ? 'APROBADO' : 'NO APROBADO',
            ]
            : tipoSeccion === 'BAJA'
                ? [
                    String(posicion),
                    eq.codigo || '-',
                    eq.capacidad || '-',
                    eq.agente || '-',
                    eq.marca || '-',
                    eq.modelo || '-',
                    eq.nSerie || '-',
                    toMonthYear(eq.fechaBaja),
                    'BAJA',
                ]
                : [
                    String(posicion),
                    eq.codigo || '-',
                    eq.capacidad || '-',
                    eq.agente || '-',
                    eq.marca || '-',
                    eq.modelo || '-',
                    eq.nSerie || '-',
                    eq.anioFabricacion || '-',
                    toMonthYear(eq.fechaHidrostatica),
                    toMonthYear(eq.fechaMantenimiento),
                ]

        let cellX = startX
        for (let c = 0; c < widths.length; c++) {
            drawCell(cellX, y, widths[c], rowH, row[c])
            cellX += widths[c]
        }
        y += rowH
    })

    return y
}

function toLongMonthYearCert(value) {
    if (!value) return ''
    const dt = new Date(value)
    if (Number.isNaN(dt.getTime())) return ''
    return dt.toLocaleDateString('es-PE', { month: 'long', year: 'numeric' }).toUpperCase()
}

function nextHydroYearCert(fechaHidrostatica) {
    if (!fechaHidrostatica) return '-'
    const date = new Date(fechaHidrostatica)
    if (Number.isNaN(date.getTime())) return '-'
    return String(date.getFullYear() + 5)
}

function nextMaintenanceMonthYearCert(fechaBase) {
    if (!fechaBase) return '-'
    const date = new Date(fechaBase)
    if (Number.isNaN(date.getTime())) return '-'
    date.setFullYear(date.getFullYear() + 1)
    return date.toLocaleDateString('es-PE', { month: 'short', year: 'numeric' }).toUpperCase()
}

function resultadoTextoCert(estadoFinal) {
    return estadoFinal === 'OPERATIVO' ? 'APROBADO' : 'NO APROBADO'
}

function aspectoTextoCert(equipo) {
    if (equipo.checklist?.estado) return String(equipo.checklist.estado).toUpperCase()
    return equipo.estadoFinal === 'OPERATIVO' ? 'BUENO' : 'OBSERVADO'
}

function drawSectionHeaderCert(doc, sectionTitle) {
    const logoPath = path.resolve('uploads/logo.png')
    try {
        doc.image(logoPath, doc.page.margins.left, 18, { width: 74 })
        doc.image(logoPath, doc.page.width - doc.page.margins.right - 74, 18, { width: 74 })

        doc.save()
        doc.opacity(0.06)
        doc.image(logoPath, doc.page.width / 2 - 180, doc.page.height / 2 - 100, { width: 360 })
        doc.restore()
    } catch (err) {
        // ignore missing logo
    }

    doc.font('Helvetica-Bold').fontSize(17).text(sectionTitle, 0, 46, { align: 'center' })
}

function drawSectionTableCert(doc, equiposPagina, tipoSeccion, indiceInicio, fechaBaseMantenimiento) {
    const pageInnerWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right
    const h1 = 18
    const h2 = 18
    const rowH = 22
    const widths = tipoSeccion === 'HIDRO'
        ? [20, 42, 56, 54, 28, 44, 44, 44, 44, 48, 60]
        : tipoSeccion === 'BAJA'
            ? [24, 44, 50, 58, 54, 58, 62, 54, 80]
            : [24, 34, 42, 52, 56, 56, 62, 42, 42, 56]
    const tableWidth = widths.reduce((a, b) => a + b, 0)
    const startX = doc.page.margins.left + ((pageInnerWidth - tableWidth) / 2)
    let y = doc.y + 14

    const drawCell = (x, yy, w, h, text, bold = false) => {
        doc.rect(x, yy, w, h).stroke()
        doc.font(bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(8)
        doc.text(text, x + 2, yy + 5, { width: w - 4, align: 'center' })
    }

    let x = startX
    if (tipoSeccion === 'HIDRO') {
        drawCell(x, y, widths[0], h1 + h2, 'N°', true); x += widths[0]
        drawCell(x, y, widths[1], h1 + h2, 'CÁP.', true); x += widths[1]
        drawCell(x, y, widths[2], h1 + h2, 'TIPO DE\nAGENTE', true); x += widths[2]
        drawCell(x, y, widths[3], h1 + h2, 'N° DE\nSERIE', true); x += widths[3]
        drawCell(x, y, widths[4], h1 + h2, 'CÓD.', true); x += widths[4]
        drawCell(x, y, widths[5] + widths[6], h1, 'PRESIÓN', true)
        drawCell(x, y + h1, widths[5], h2, 'TRABAJO', true)
        drawCell(x + widths[5], y + h1, widths[6], h2, 'PRUEBA', true)
        x += widths[5] + widths[6]
        drawCell(x, y, widths[7] + widths[8], h1, 'ASPECTO', true)
        drawCell(x, y + h1, widths[7], h2, 'INTERNO', true)
        drawCell(x + widths[7], y + h1, widths[8], h2, 'EXTERNO', true)
        x += widths[7] + widths[8]
        drawCell(x, y, widths[9], h1 + h2, 'PRÓX.\nPRUEBA', true); x += widths[9]
        drawCell(x, y, widths[10], h1 + h2, 'RESULTADO', true)
    } else if (tipoSeccion === 'BAJA') {
        drawCell(x, y, widths[0], h1 + h2, 'N°', true); x += widths[0]
        drawCell(x, y, widths[1], h1 + h2, 'CÓD.', true); x += widths[1]
        drawCell(x, y, widths[2], h1 + h2, 'CÁP.', true); x += widths[2]
        drawCell(x, y, widths[3], h1 + h2, 'TIPO', true); x += widths[3]
        drawCell(x, y, widths[4], h1 + h2, 'MARCA', true); x += widths[4]
        drawCell(x, y, widths[5], h1 + h2, 'MODELO', true); x += widths[5]
        drawCell(x, y, widths[6], h1 + h2, 'N° SERIE', true); x += widths[6]
        drawCell(x, y, widths[7], h1 + h2, 'FECHA\nBAJA', true); x += widths[7]
        drawCell(x, y, widths[8], h1 + h2, 'ESTADO', true)
    } else {
        drawCell(x, y, widths[0], h1 + h2, 'N°', true); x += widths[0]
        drawCell(x, y, widths[1], h1 + h2, 'COD.', true); x += widths[1]
        drawCell(x, y, widths[2], h1 + h2, 'CAP.', true); x += widths[2]
        drawCell(x, y, widths[3], h1 + h2, 'TIPO', true); x += widths[3]
        drawCell(x, y, widths[4], h1 + h2, 'MARCA', true); x += widths[4]
        drawCell(x, y, widths[5], h1 + h2, 'MODELO', true); x += widths[5]
        drawCell(x, y, widths[6], h1 + h2, 'N° SERIE', true); x += widths[6]
        drawCell(x, y, widths[7], h1 + h2, 'AÑO\nFAB.', true); x += widths[7]
        drawCell(x, y, widths[8], h1 + h2, 'P.H.', true); x += widths[8]
        drawCell(x, y, widths[9], h1 + h2, 'PROX.\nMANTTO.', true)
    }
    y += h1 + h2

    if (!equiposPagina.length) {
        doc.font('Helvetica').fontSize(10).text('Sin extintores en esta sección.', startX, y + 12)
        return y + 40
    }

    equiposPagina.forEach((eq, index) => {
        const posicion = indiceInicio + index + 1
        const row = tipoSeccion === 'HIDRO'
            ? [
                String(posicion),
                eq.capacidad || '-',
                eq.agente || '-',
                eq.nSerie || '-',
                eq.codigo || '-',
                eq.presionTrabajo || '-',
                eq.presionPrueba || '-',
                aspectoTextoCert(eq),
                aspectoTextoCert(eq),
                nextHydroYearCert(eq.fechaHidrostatica),
                resultadoTextoCert(eq.estadoFinal || ''),
            ]
            : tipoSeccion === 'BAJA'
                ? [
                    String(posicion),
                    eq.codigo || '-',
                    eq.capacidad || '-',
                    eq.agente || '-',
                    eq.marca || '-',
                    eq.modelo || '-',
                    eq.nSerie || '-',
                    toMonthYear(eq.fechaBaja),
                    'BAJA',
                ]
                : [
                    String(posicion),
                    eq.codigo || '-',
                    eq.capacidad || '-',
                    eq.agente || '-',
                    eq.marca || '-',
                    eq.modelo || '-',
                    eq.nSerie || '-',
                    eq.anioFabricacion || '-',
                    toMonthYear(eq.fechaHidrostatica),
                    nextMaintenanceMonthYearCert(fechaBaseMantenimiento),
                ]

        let cellX = startX
        for (let c = 0; c < widths.length; c++) {
            drawCell(cellX, y, widths[c], rowH, row[c])
            cellX += widths[c]
        }
        y += rowH
    })

    return y
}

function drawSectionClosingTextCert(doc, tipoSeccion, blockX, blockWidth) {
    const normativaOper = 'Cumpliendo con los requerimientos de los estándares de la NTP 350.043-1:2011 Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 1a. Ed." y la NFPA 10 Norma para Extintores Portátiles Contra Incendios.'
    const normativaHidro = 'La prueba hidrostática se ha realizado de acuerdo con los estándares de la NTP 350.043-1:2011 Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 3a. Ed." y la NTP 833.030:2012: Extintores Portátiles. Servicio de inspección, mantenimiento, recarga y prueba hidrostática. Rotulado. 3a. ed.'
    const normativaBaja = 'La baja de los equipos se ha realizado conforme a la evaluación técnica de seguridad y trazabilidad, cumpliendo con los estándares aplicables para el retiro de extintores fuera de vida útil o en condición no operativa.'

    const cierreOper = 'Del mantenimiento realizado se concluye que los extintores contra incendios se encuentran en buen estado lo cual garantiza su operatividad y funcionamiento, teniendo una vigencia de un año contado a partir de la emisión del presente documento.'
    const cierreHidro = 'Cualquier evento o falla posterior por la mala manipulación, el mal uso o desuso, o uso distinto al que está destinado es de responsabilidad del cliente.'
    const cierreBaja = 'Concluida la evaluación, los equipos listados se consideran no aptos para operación y se recomienda su retiro definitivo de servicio.'

    const normativa = tipoSeccion === 'HIDRO' ? normativaHidro : (tipoSeccion === 'BAJA' ? normativaBaja : normativaOper)
    const cierre = tipoSeccion === 'HIDRO' ? cierreHidro : (tipoSeccion === 'BAJA' ? cierreBaja : cierreOper)

    doc.font('Helvetica').fontSize(10).text(normativa, blockX, doc.y + 12, {
        align: 'justify',
        width: blockWidth,
    })
    doc.moveDown(0.8)
    doc.font('Helvetica').text(cierre, { align: 'justify', width: blockWidth })
    doc.moveDown(1)
    doc.font('Helvetica').text('Realizado por:', { width: blockWidth })

    const firmaPath = path.resolve('uploads/firma.png')
    try {
        doc.image(firmaPath, blockX, doc.y + 6, { width: 150 })
    } catch (err) {
        // ignore missing signature image
    }
}

function drawUnifiedSectionPageCert(doc, contexto) {
    const {
        tipoSeccion,
        numeroCertificado,
        fechaEmision,
        empresaNombre,
        ruc,
        equiposPagina,
        indiceInicio,
        fechaBaseMantenimiento,
        totalSeccion,
        paginaSeccion,
        totalPaginasSeccion,
    } = contexto

    const sectionTitle = tipoSeccion === 'HIDRO'
        ? 'CERTIFICADO DE PRUEBA HIDROSTÁTICA'
        : tipoSeccion === 'BAJA'
            ? 'CERTIFICADO DE BAJA'
            : 'PROTOCOLO DE OPERATIVIDAD Y MANTENIMIENTO DE EXTINTORES\nCONTRA INCENDIOS'

    const intro = tipoSeccion === 'HIDRO'
        ? 'Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la prueba hidrostática de los extintores contra incendios citados en el listado adjunto ubicados en '
        : tipoSeccion === 'BAJA'
            ? 'Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la evaluación técnica para la baja de los extintores contra incendios citados en el listado adjunto ubicados en '
            : 'Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la inspección y mantenimiento de los extintores contra incendios citados en el listado adjunto ubicados en '

    const pageInnerWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right
    const blockX = doc.page.margins.left + 14
    const blockWidth = pageInnerWidth - 28

    drawSectionHeaderCert(doc, sectionTitle)
    doc.moveDown(1.6)
    doc.font('Helvetica-Bold').fontSize(11).text(`Certificado: ${numeroCertificado}`, { align: 'center' })
    doc.text(`Fecha de Emisión: ${fechaEmision}`, { align: 'center' })
    doc.font('Helvetica').fontSize(8).text(
        `Extintores correspondientes: ${totalSeccion} | Página sección: ${paginaSeccion}/${totalPaginasSeccion}`,
        { align: 'center' },
    )
    doc.moveDown(0.8)

    doc.font('Helvetica').fontSize(10)
    doc.text(intro, blockX, doc.y, {
        continued: true,
        align: 'justify',
        width: blockWidth,
    })
    doc.font('Helvetica-Bold').text(empresaNombre, { continued: true, width: blockWidth, align: 'justify' })
    doc.font('Helvetica').text(', identificado con ', { continued: true, width: blockWidth, align: 'justify' })
    doc.font('Helvetica-Bold').text(`RUC N° ${ruc}`, { continued: true, width: blockWidth, align: 'justify' })
    doc.font('Helvetica').text(' y ubicado en ', { continued: true, width: blockWidth, align: 'justify' })
    doc.font('Helvetica-Bold').text('PRINCIPAL.', { align: 'justify', width: blockWidth })

    const yFinal = drawSectionTableCert(
        doc,
        equiposPagina,
        tipoSeccion,
        indiceInicio,
        fechaBaseMantenimiento,
    )

    doc.y = yFinal
    drawSectionClosingTextCert(doc, tipoSeccion, blockX, blockWidth)
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

            const doc = new PDFDocument({ margin: 24, size: 'A4' })

            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader(
                'Content-Disposition',
                `attachment; filename=reporte-fotografico-${servicioId}.pdf`
            )

            doc.pipe(res)

            const logoPath = path.resolve('uploads/logo.png')
            try {
                doc.image(
                    logoPath,
                    doc.page.width - doc.page.margins.right - 100,
                    20,
                    { width: 100 },
                )
            } catch (err) {
                // ignore missing logo
            }

            const titleWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right
            doc.font('Helvetica-Bold').fontSize(12).text(
                'REPORTE FOTOGRÁFICO DE EXTINTORES CONTRA INCENDIOS',
                doc.page.margins.left,
                36,
                {
                    width: titleWidth,
                    align: 'center',
                },
            )

            const infoY = 78
            const labelX = doc.page.margins.left
            const valueX = labelX + 80

            doc.font('Helvetica').fontSize(10)
            doc.text('Cliente :', labelX, infoY)
            doc.text(reporte.cliente.razonSocial, valueX, infoY)
            doc.text('Inspector :', labelX, infoY + 14)
            doc.text(reporte.servicio.user?.name ?? '-', valueX, infoY + 14)
            doc.text('Fecha :', labelX, infoY + 28)
            doc.text(reporte.servicio.fechaInicio ?? '-', valueX, infoY + 28)

            const tableTop = infoY + 52
            const columns = [
                { header: 'COD.', key: 'codigo', width: 55 },
                { header: 'CAP.', key: 'capacidad', width: 50 },
                { header: 'AGENTE', key: 'agente', width: 55 },
                { header: 'N°SERIE', key: 'nSerie', width: 80 },
                { header: 'OBSERVACIÓN', key: 'estadoFinal', width: 80 },
                { header: 'FOTOGRAFÍA', key: 'foto', width: 165 },
                { header: 'RECOMENDACIONES', key: 'recomendaciones', width: 120 },
            ]
            const rowHeight = 120
            const startX = doc.page.margins.left
            const bottomMargin = doc.page.height - doc.page.margins.bottom
            let y = tableTop

            const drawTableHeader = () => {
                let x = startX
                doc.font('Helvetica-Bold').fontSize(9)
                columns.forEach((column) => {
                    doc.rect(x, y, column.width, 24).fill('#c20b0b').stroke()
                    doc.fillColor('white').text(column.header, x + 4, y + 6, {
                        width: column.width - 8,
                        align: 'center',
                    })
                    x += column.width
                })
                y += 24
                doc.fillColor('black').font('Helvetica').fontSize(9)
            }

            const drawRow = async (equipo) => {
                let x = startX
                const rowY = y
                const photoUrl = equipo.fotosArray?.[0] || equipo.fotos?.foto1Url || equipo.fotos?.foto2Url || equipo.fotos?.foto3Url || null
                const photoBuffer = photoUrl ? await descargarImagenPrivada(photoUrl) : null
                const row = {
                    codigo: equipo.codigo || '',
                    capacidad: equipo.capacidad || '',
                    agente: equipo.agente || '',
                    nSerie: equipo.nSerie || '',
                    estadoFinal: equipo.estadoFinal || '',
                    recomendaciones: equipo.recomendaciones || 'Ninguna',
                }

                columns.forEach((column) => {
                    doc.rect(x, rowY, column.width, rowHeight).stroke()
                    if (column.key === 'foto') {
                        if (photoBuffer) {
                            try {
                                doc.image(photoBuffer, x + 6, rowY + 6, {
                                    fit: [column.width - 12, rowHeight - 12],
                                    align: 'center',
                                    valign: 'center',
                                })
                            } catch (err) {
                                doc.fontSize(7).text('Foto no disponible', x + 6, rowY + 10, {
                                    width: column.width - 12,
                                    align: 'center',
                                })
                            }
                        } else {
                            doc.fontSize(7).text('Sin fotografía', x + 6, rowY + 10, {
                                width: column.width - 12,
                                align: 'center',
                            })
                        }
                    } else {
                        const text = row[column.key] ?? '-'
                        doc.font('Helvetica').fontSize(9).text(text, x + 6, rowY + 8, {
                            width: column.width - 12,
                            align: 'left',
                            lineBreak: true,
                        })
                    }
                    x += column.width
                })
                y += rowHeight
            }

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []
            drawTableHeader()

            for (let index = 0; index < equipos.length; index++) {
                if (y + rowHeight + 20 > bottomMargin) {
                    doc.addPage({ margin: 24, size: 'A4' })
                    y = doc.page.margins.top
                    drawTableHeader()
                }
                await drawRow(equipos[index])
            }

            doc.end()
        } catch (error) {
            console.error(error)

            if (!res.headersSent) {
                res.status(500).json({ message: 'Error al generar certificado' })
            }
        }
    },

    async descargarCertificadoServicio(req, res) {
        try {
            const { servicioId } = req.params
            const reporte = await ReporteInspeccionService.generar(Number(servicioId))

            if (!reporte) {
                return res.status(404).json({ message: 'Servicio no encontrado' })
            }

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []
            const { oper, hidro, baja } = clasificarEquiposServicio(equipos)

            const secciones = [
                {
                    tipo: 'OPER',
                    titulo: 'SECCIÓN 1 - INTEGRIDAD Y MANTENIMIENTO',
                    equipos: oper,
                },
                {
                    tipo: 'HIDRO',
                    titulo: 'SECCIÓN 2 - PRUEBA HIDROSTÁTICA',
                    equipos: hidro,
                },
                {
                    tipo: 'BAJA',
                    titulo: 'SECCIÓN 3 - EXTINTORES DADOS DE BAJA',
                    equipos: baja,
                },
            ]

            const numeroCertificado = reporte.servicio?.numeroCertificado || `SERVICIO-${servicioId}`
            const fechaBase = reporte.servicio?.fechaEmision || reporte.servicio?.fechaInicio
            const fechaEmision = toLongMonthYearCert(fechaBase)
            const empresaNombre = (reporte.cliente?.razonSocial || '').toUpperCase()
            const ruc = reporte.cliente?.ruc || ''
            const doc = new PDFDocument({ margin: 34, size: 'A4' })
            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader(
                'Content-Disposition',
                `attachment; filename=CERTIFICADO_SERVICIO_${numeroCertificado}.pdf`,
            )
            doc.pipe(res)

            const rowsPerPage = 10

            secciones.forEach((seccion, idxSeccion) => {
                const total = seccion.equipos.length
                const totalPaginas = Math.max(1, Math.ceil(total / rowsPerPage))

                for (let pagina = 0; pagina < totalPaginas; pagina++) {
                    if (!(idxSeccion === 0 && pagina === 0)) {
                        doc.addPage({ margin: 34, size: 'A4' })
                    }

                    const inicio = pagina * rowsPerPage
                    const equiposPagina = seccion.equipos.slice(inicio, inicio + rowsPerPage)

                    drawUnifiedSectionPageCert(doc, {
                        tipoSeccion: seccion.tipo,
                        numeroCertificado,
                        fechaEmision,
                        empresaNombre,
                        ruc,
                        equiposPagina,
                        indiceInicio: inicio,
                        fechaBaseMantenimiento: fechaBase,
                        totalSeccion: total,
                        paginaSeccion: pagina + 1,
                        totalPaginasSeccion: totalPaginas,
                    })
                }
            })

            doc.end()
        } catch (error) {
            console.error(error)
            if (!res.headersSent) {
                res.status(500).json({ message: 'Error al generar PDF unificado del servicio' })
            }
        }
    },

    async descargarWord(req, res) {
        try {
            const { servicioId } = req.params
            const reporte = await ReporteInspeccionService.generar(Number(servicioId))

            if (!reporte) {
                return res.status(404).json({ message: 'Servicio no encontrado' })
            }

            const empresaNombre = (reporte.cliente.razonSocial || '').toUpperCase()
            const ruc = reporte.cliente.ruc || ''
            const fechaReferencia = reporte.servicio.fechaEmision || reporte.servicio.fechaInicio
            const fechaEmision = (() => {
                const fecha = new Date(fechaReferencia)
                if (!Number.isNaN(fecha.getTime())) {
                    return fecha.toLocaleDateString('es-PE', { month: 'long', year: 'numeric' }).toUpperCase()
                }
                return fechaReferencia || ''
            })()
            const certificadoTipo = (reporte.servicio?.certificadoTipo || '').toUpperCase()
            const fallbackTipo = (reporte.servicio?.tipo || '').toUpperCase()

            const tipoPlantilla = certificadoTipo
                || (fallbackTipo === 'MANTENIMIENTO' ? 'OPER' : 'HIDRO')

            const isHydro = tipoPlantilla === 'HIDRO'
            const isBaja = tipoPlantilla === 'BAJA'
            const isReporteTecnico = tipoPlantilla === 'REPORTE_TECNICO'
            const isOperatividad = tipoPlantilla === 'OPER'

            const numeroCertificado = reporte.servicio?.numeroCertificado || servicioId

            const tituloCertificado = isHydro
                ? 'CERTIFICADO DE PRUEBA HIDROSTÁTICA'
                : isBaja
                    ? 'CERTIFICADO DE BAJA'
                    : isReporteTecnico
                        ? 'REPORTE TÉCNICO'
                        : 'CERTIFICADO DE OPERATIVIDAD Y MANTENIMIENTO'

            const introTexto = isHydro
                ? 'La Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la prueba hidrostática de los extintores contra incendios citados en el listado adjunto de la empresa '
                : isBaja
                    ? 'La Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la evaluación técnica para la baja de los extintores contra incendios citados en el listado adjunto de la empresa '
                    : isReporteTecnico
                        ? 'La Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó el reporte técnico de los extintores contra incendios citados en el listado adjunto de la empresa '
                        : 'La Organización Iberoamericana de Seguridad Contra Incendios SAC, deja constancia que se realizó la inspección y mantenimiento de los extintores contra incendios citados en el listado adjunto de la empresa '

            const normativaTexto = isHydro
                ? 'La prueba hidrostática se ha realizado de acuerdo con los estándares de la NTP 350.043-1:2011 Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 3a. Ed." y la NTP 833.030:2012: Extintores Portátiles. Servicio de inspección, mantenimiento, recarga y prueba hidrostática. Rotulado. 3a. ed.'
                : isBaja
                    ? 'La baja de los equipos se ha realizado conforme a la evaluación técnica de seguridad y trazabilidad, cumpliendo con los estándares aplicables para el retiro de extintores fuera de vida útil o en condición no operativa.'
                    : isReporteTecnico
                        ? 'El reporte técnico se ha elaborado con base en la evaluación visual, funcional y documental de los equipos, considerando criterios de seguridad operacional y cumplimiento normativo aplicable.'
                        : 'Cumpliendo con los requerimientos de los estándares de la NTP 350.043-1:2011 Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 1a. Ed." y la NFPA 10 Norma para Extintores Portátiles Contra Incendios.'

            const cierreTexto = isHydro
                ? 'Cualquier evento o falla posterior por la mala manipulación, el mal uso o desuso, o uso distinto al que está destinado es de responsabilidad del cliente.'
                : isBaja
                    ? 'Concluida la evaluación, los equipos listados se consideran no aptos para operación y se recomienda su retiro definitivo de servicio.'
                    : isReporteTecnico
                        ? 'La información contenida en este reporte representa el estado técnico observado al momento de la evaluación y debe ser considerada para la toma de decisiones operativas.'
                        : 'Del mantenimiento realizado se concluye que los extintores contra incendios se encuentran en buen estado lo cual garantiza su operatividad y funcionamiento, teniendo una vigencia de un año contado a partir de la emisión del presente documento.'

            const conclusionTexto = isHydro
                ? 'Los equipos han pasado la prueba hidrostática correspondiente, de acuerdo a la normativa aplicable.'
                : isBaja
                    ? 'Los equipos se encuentran clasificados para baja definitiva conforme a la evaluación técnica aplicada.'
                    : isReporteTecnico
                        ? 'Se emite el presente reporte técnico para las acciones correctivas y de seguimiento que correspondan.'
                        : 'Los equipos se encuentran operativos de acuerdo con la revisión efectuada.'
            const doc = new PDFDocument({ margin: 34, size: 'A4' })
            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader(
                'Content-Disposition',
                `attachment; filename=certificado-prueba-hidrostatica-${servicioId}.pdf`,
            )
            doc.pipe(res)

            const pageInnerWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right
            const blockX = doc.page.margins.left + 14
            const blockWidth = pageInnerWidth - 28

            const logoPath = path.resolve('uploads/logo.png')
            try {
                doc.image(logoPath, doc.page.margins.left, 18, { width: 74 })
                doc.image(logoPath, doc.page.width - doc.page.margins.right - 74, 18, { width: 74 })

                // Watermark suave de fondo para acercar el estilo visual del certificado.
                doc.save()
                doc.opacity(0.06)
                doc.image(logoPath, doc.page.width / 2 - 180, doc.page.height / 2 - 100, { width: 360 })
                doc.restore()
            } catch (err) {
                // ignore missing logo
            }

            doc.font('Helvetica-Bold').fontSize(17).text(tituloCertificado, 0, 48, { align: 'center' })
            doc.moveDown(1.9)
            doc.font('Helvetica-Bold').fontSize(11).text(`Certificado: ${numeroCertificado}`, { align: 'center' })
            doc.text(`Fecha de Emisión: ${fechaEmision}`, { align: 'center' })
            doc.moveDown(0.9)

            doc.font('Helvetica').fontSize(10)
            doc.text(introTexto, blockX, doc.y, {
                continued: true,
                align: 'justify',
                width: blockWidth,
            })
            doc.font('Helvetica-Bold').text(empresaNombre, { continued: true, width: blockWidth, align: 'justify' })
            doc.font('Helvetica').text(', identificado con ', { continued: true, width: blockWidth, align: 'justify' })
            doc.font('Helvetica-Bold').text(`RUC N° ${ruc}`, { continued: true, width: blockWidth, align: 'justify' })
            doc.font('Helvetica').text(' y ubicado en ', { continued: true, width: blockWidth, align: 'justify' })
            doc.font('Helvetica-Bold').text('PRINCIPAL.', { align: 'justify', width: blockWidth })

            const toMonthYear = (value) => {
                if (!value) return '-'
                const dt = new Date(value)
                if (Number.isNaN(dt.getTime())) return '-'
                return dt.toLocaleDateString('es-PE', { month: 'short', year: 'numeric' }).toUpperCase()
            }

            const nextHydroYear = (fechaHidrostatica) => {
                if (!fechaHidrostatica) return '-'
                const date = new Date(fechaHidrostatica)
                if (Number.isNaN(date.getTime())) return '-'
                return String(date.getFullYear() + 5)
            }

            const resultadoTexto = (estadoFinal) =>
                estadoFinal === 'OPERATIVO' ? 'APROBADO' : 'NO APROBADO'

            const aspectoTexto = (equipo) => {
                if (equipo.checklist?.estado) return String(equipo.checklist.estado).toUpperCase()
                return equipo.estadoFinal === 'OPERATIVO' ? 'BUENO' : 'OBSERVADO'
            }

            const h1 = 18
            const h2 = 18
            const rowH = 22
            const widths = isHydro
                ? [20, 42, 56, 54, 28, 44, 44, 44, 44, 48, 60]
                : isBaja
                    ? [24, 44, 50, 58, 54, 58, 62, 54, 80]
                    : [24, 34, 42, 52, 56, 56, 62, 42, 42, 56]
            const tableWidth = widths.reduce((a, b) => a + b, 0)
            const startX = doc.page.margins.left + ((pageInnerWidth - tableWidth) / 2)
            let y = doc.y + 14
            const rowsPerPage = 10

            const drawCell = (x, yy, w, h, text, opts = {}) => {
                doc.rect(x, yy, w, h).stroke()
                doc.font(opts.bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(opts.size || 8)
                doc.text(text, x + 2, yy + 5, { width: w - 4, align: opts.align || 'center' })
            }

            const drawHeader = () => {
                let x = startX
                if (isHydro) {
                    drawCell(x, y, widths[0], h1 + h2, 'N°', { bold: true }); x += widths[0]
                    drawCell(x, y, widths[1], h1 + h2, 'CÁP.', { bold: true }); x += widths[1]
                    drawCell(x, y, widths[2], h1 + h2, 'TIPO DE\nAGENTE', { bold: true }); x += widths[2]
                    drawCell(x, y, widths[3], h1 + h2, 'N° DE\nSERIE', { bold: true }); x += widths[3]
                    drawCell(x, y, widths[4], h1 + h2, 'CÓD.', { bold: true }); x += widths[4]

                    drawCell(x, y, widths[5] + widths[6], h1, 'PRESIÓN', { bold: true })
                    drawCell(x, y + h1, widths[5], h2, 'TRABAJO', { bold: true })
                    drawCell(x + widths[5], y + h1, widths[6], h2, 'PRUEBA', { bold: true })
                    x += widths[5] + widths[6]

                    drawCell(x, y, widths[7] + widths[8], h1, 'ASPECTO', { bold: true })
                    drawCell(x, y + h1, widths[7], h2, 'INTERNO', { bold: true })
                    drawCell(x + widths[7], y + h1, widths[8], h2, 'EXTERNO', { bold: true })
                    x += widths[7] + widths[8]

                    drawCell(x, y, widths[9], h1 + h2, 'PRÓX.\nPRUEBA', { bold: true }); x += widths[9]
                    drawCell(x, y, widths[10], h1 + h2, 'RESULTADO', { bold: true })
                } else if (isBaja) {
                    drawCell(x, y, widths[0], h1 + h2, 'N°', { bold: true }); x += widths[0]
                    drawCell(x, y, widths[1], h1 + h2, 'CÓD.', { bold: true }); x += widths[1]
                    drawCell(x, y, widths[2], h1 + h2, 'CÁP.', { bold: true }); x += widths[2]
                    drawCell(x, y, widths[3], h1 + h2, 'TIPO', { bold: true }); x += widths[3]
                    drawCell(x, y, widths[4], h1 + h2, 'MARCA', { bold: true }); x += widths[4]
                    drawCell(x, y, widths[5], h1 + h2, 'MODELO', { bold: true }); x += widths[5]
                    drawCell(x, y, widths[6], h1 + h2, 'N° SERIE', { bold: true }); x += widths[6]
                    drawCell(x, y, widths[7], h1 + h2, 'FECHA\nBAJA', { bold: true }); x += widths[7]
                    drawCell(x, y, widths[8], h1 + h2, 'ESTADO', { bold: true })
                } else {
                    drawCell(x, y, widths[0], h1 + h2, 'N°', { bold: true }); x += widths[0]
                    drawCell(x, y, widths[1], h1 + h2, 'CÓD.', { bold: true }); x += widths[1]
                    drawCell(x, y, widths[2], h1 + h2, 'CÁP.', { bold: true }); x += widths[2]
                    drawCell(x, y, widths[3], h1 + h2, 'TIPO', { bold: true }); x += widths[3]
                    drawCell(x, y, widths[4], h1 + h2, 'MARCA', { bold: true }); x += widths[4]
                    drawCell(x, y, widths[5], h1 + h2, 'MODELO', { bold: true }); x += widths[5]
                    drawCell(x, y, widths[6], h1 + h2, 'N° SERIE', { bold: true }); x += widths[6]
                    drawCell(x, y, widths[7], h1 + h2, 'AÑO\nFAB.', { bold: true }); x += widths[7]
                    drawCell(x, y, widths[8], h1 + h2, 'P.H.', { bold: true }); x += widths[8]
                    drawCell(x, y, widths[9], h1 + h2, 'PROX.\nMANTTO.', { bold: true })
                }
                y += h1 + h2
            }

            drawHeader()

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []

            for (let start = 0; start < equipos.length; start += rowsPerPage) {
                if (start > 0) {
                    doc.addPage({ margin: 34, size: 'A4' })
                    y = doc.page.margins.top + 20
                    drawHeader()
                }

                const chunk = equipos.slice(start, start + rowsPerPage)
                chunk.forEach((eq, chunkIndex) => {
                    const globalIndex = start + chunkIndex
                    const aspecto = aspectoTexto(eq)
                    const row = isHydro
                        ? [
                            String(globalIndex + 1),
                            eq.capacidad || '-',
                            eq.agente || '-',
                            eq.nSerie || '-',
                            eq.codigo || '-',
                            eq.presionTrabajo || '-',
                            eq.presionPrueba || '-',
                            aspecto,
                            aspecto,
                            nextHydroYear(eq.fechaHidrostatica),
                            resultadoTexto(eq.estadoFinal || ''),
                        ]
                        : isBaja
                            ? [
                                String(globalIndex + 1),
                                eq.codigo || '-',
                                eq.capacidad || '-',
                                eq.agente || '-',
                                eq.marca || '-',
                                eq.modelo || '-',
                                eq.nSerie || '-',
                                toMonthYear(eq.fechaBaja),
                                'BAJA',
                            ]
                            : [
                                String(globalIndex + 1),
                                eq.codigo || '-',
                                eq.capacidad || '-',
                                eq.agente || '-',
                                eq.marca || '-',
                                eq.modelo || '-',
                                eq.nSerie || '-',
                                eq.anioFabricacion || '-',
                                toMonthYear(eq.fechaHidrostatica),
                                toMonthYear(eq.fechaMantenimiento),
                            ]

                    let x = startX
                    for (let c = 0; c < widths.length; c++) {
                        drawCell(x, y, widths[c], rowH, row[c], { size: 8 })
                        x += widths[c]
                    }
                    y += rowH
                })
            }

            const requiredTextHeight = 170
            if (doc.y + requiredTextHeight > doc.page.height - doc.page.margins.bottom) {
                doc.addPage({ margin: 34, size: 'A4' })
            }

            doc.x = blockX
            doc.y = y + 12
            const textoWidth = blockWidth
            doc.font('Helvetica').fontSize(10)
            if (isHydro) {
                doc.text('La prueba hidrostática se ha realizado de acuerdo con los estándares de la ', blockX, doc.y, { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica-Bold').text('NTP 350.043-1:2011', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica').text(' Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 3a. Ed." y la ', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica-Bold').text('NTP 833.030:2012', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica').text(': Extintores Portátiles. Servicio de inspección, mantenimiento, recarga y prueba hidrostática. Rotulado. 3a. ed.', { align: 'justify', width: textoWidth })
            } else if (isOperatividad) {
                doc.text('Cumpliendo con los requerimientos de los estándares de la ', blockX, doc.y, { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica-Bold').text('NTP 350.043-1:2011', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica').text(' Extintores Portátiles "Selección, distribución, inspección, mantenimiento, recarga y prueba hidrostática. 1a. Ed." y la ', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica-Bold').text('NFPA 10', { continued: true, align: 'justify', width: textoWidth })
                doc.font('Helvetica').text(' Norma para Extintores Portátiles Contra Incendios.', { align: 'justify', width: textoWidth })
            } else {
                doc.text(normativaTexto, blockX, doc.y, { align: 'justify', width: textoWidth })
            }
            doc.moveDown(0.8)
            doc.font('Helvetica').text(cierreTexto, { align: 'justify', width: textoWidth })
            doc.moveDown(0.8)
            doc.font('Helvetica-Bold').text('Conclusión: ', { continued: true, width: textoWidth })
            doc.font('Helvetica').text(conclusionTexto, { width: textoWidth })
            doc.moveDown(1)
            doc.font('Helvetica').text('Realizado por:', { width: textoWidth })

            const firmaPath = path.resolve('uploads/firma.png')
            const firmaWidth = 150
            const firmaHeight = 60

            if (doc.y + firmaHeight + 10 > doc.page.height - doc.page.margins.bottom) {
                doc.addPage({ margin: 34, size: 'A4' })
                doc.font('Helvetica').fontSize(10).text('Realizado por:', blockX, doc.y, { width: textoWidth })
            }

            try {
                doc.image(firmaPath, blockX, doc.y + 6, { width: firmaWidth })
            } catch (err) {
                // ignore missing signature image
            }

            doc.end()
        } catch (error) {
            console.error(error)
            if (!res.headersSent) {
                res.status(500).json({ message: 'Error al generar PDF del certificado' })
            }
        }
    },
}