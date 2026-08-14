import PDFDocument from 'pdfkit'
import path from 'path'
import { ReporteMantenimientoAnualService } from '../../service/reporte/mantenimientoAnual.service.js'

const M = 17
const PAGE_W = 595.28

function dateLabel(value) {
    if (!value) return '-'
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return '-'
    return date.toLocaleDateString('es-PE', { month: 'short', year: 'numeric' }).toUpperCase()
}

function fullDateLabel(value) {
    if (!value) return '-'
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return '-'
    return date.toLocaleDateString('es-PE', { timeZone: 'America/Lima' })
}

// En InspeccionDetalle, "SI" significa que el componente cumple. Como esta
// tabla pregunta si existe el defecto, el valor debe mostrarse invertido.
function defectResult(value) {
    if (value === null || value === undefined || value === '') return 'N.A.'
    const normalized = String(value).trim().toUpperCase()
    if (['SI', 'SÍ', 'C', 'CUMPLE', 'OPERATIVO'].includes(normalized)) return 'NO'
    if (['NO', 'NC', 'NO CUMPLE', 'INOPERATIVO'].includes(normalized)) return 'SI'
    return normalized
}

function cell(doc, x, y, w, h, text, options = {}) {
    doc.rect(x, y, w, h).stroke('#111111')
    doc.save().rect(x + 1, y + 1, w - 2, h - 2).clip()
    doc.font(options.bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(options.size || 6)
    doc.text(String(text ?? '-'), x + 3, y + (options.top ?? 5), {
        width: w - 6,
        height: h - 5,
        align: options.align || 'center',
        ellipsis: true,
    })
    doc.restore()
}

function section(doc, number, title, y) {
    doc.font('Helvetica-Bold').fontSize(8).text(String(number), M + 10, y)
    doc.text(title, M + 30, y)
}

function keyValueTable(doc, x, y, width, rows) {
    const labelWidth = 91
    const rowH = 20
    rows.forEach(([label, value], index) => {
        cell(doc, x, y + (index * rowH), labelWidth, rowH, label, { bold: true })
        cell(doc, x + labelWidth, y + (index * rowH), width - labelWidth, rowH, value)
    })
}

function componentTable(doc, x, y, groups) {
    const partW = 84
    const reviewW = 142
    const resultW = 28
    let currentY = y

    cell(doc, x, currentY, partW, 22, 'PARTE DEL\nEXTINTOR', { bold: true })
    cell(doc, x + partW, currentY, reviewW, 22, 'REVISIÓN', { bold: true })
    cell(doc, x + partW + reviewW, currentY, resultW, 22, 'SI/NO', { bold: true })
    currentY += 22

    groups.forEach(({ part, checks }) => {
        const height = checks.length * 13
        cell(doc, x, currentY, partW, height, part, { bold: true })
        checks.forEach((check, index) => {
            const label = typeof check === 'string' ? check : check.label
            const result = typeof check === 'string' ? 'N.A.' : defectResult(check.value)
            cell(doc, x + partW, currentY + (index * 13), reviewW, 13, label, { align: 'left', top: 2 })
            cell(doc, x + partW + reviewW, currentY + (index * 13), resultW, 13, result, { top: 2 })
        })
        currentY += height
    })
}

function serviceText(detail) {
    if (!detail) return '-'
    const values = []
    if (detail.mantenimiento) values.push('MANTENIMIENTO')
    if (detail.recarga) values.push('RECARGA')
    if (detail.pruebaHidrostatica) values.push('PRUEBA HIDROSTÁTICA')
    if (detail.pintura) values.push('PINTURA')
    if (detail.cambioPartes) values.push('CAMBIO DE PARTES')
    return values.join(', ') || '-'
}

function drawPage(doc, servicio, servicioExtintor, index, total) {
    const e = servicioExtintor.extintor
    const md = servicioExtintor.mantenimientoDetalle
    const inspection = servicioExtintor.inspeccionDetalle
    const inspectionDate = servicioExtintor.ultimaInspeccion?.servicio?.dateStart
    const inspectionServiceId = servicioExtintor.ultimaInspeccion?.servicio?.id
    const inspectionObservation = inspection?.observaciones || 'SIN OBSERVACIONES'
    const client = servicio.sede.client
    const leftX = M
    const halfGap = 10
    const halfW = (PAGE_W - (M * 2) - halfGap) / 2

    doc.lineWidth(0.65).rect(4, 5, PAGE_W - 8, 832).stroke('#111111')
    try {
        doc.image(path.resolve('uploads/logo.png'), PAGE_W - 76, 20, { width: 55 })
    } catch {
        // Continúa sin logo.
    }

    doc.font('Helvetica-Bold').fontSize(10).text(
        'REPORTE TÉCNICO DE SERVICIO INSPECCIÓN, MANTENIMIENTO, RECARGA Y PRUEBA\nHIDROSTÁTICA DE EXTINTORES CONTRA INCENDIOS',
        35,
        17,
        { width: 480, align: 'center' },
    )
    doc.font('Helvetica').fontSize(5).text(`Ficha ${index + 1} de ${total}`, PAGE_W - 90, 55, { width: 70, align: 'right' })

    section(doc, 1, 'DATOS GENERALES', 78)
    doc.font('Helvetica').fontSize(7).text('De la Empresa Contratante', leftX + 30, 101)
    doc.text('De la Empresa Ejecutora', leftX + halfW + halfGap + 5, 101)

    keyValueTable(doc, leftX, 116, halfW, [
        ['EMPRESA', client.razonSocial],
        ['INSTALACIÓN', servicio.sede.name_sede],
        ['RESPONSABLE', servicio.sede.manager_name],
        ['DIRECCIÓN', servicio.sede.address],
        ['CIUDAD', servicio.sede.city],
    ])
    keyValueTable(doc, leftX + halfW + halfGap, 116, halfW, [
        ['PROYECTO', 'MANTENIMIENTO DE EXTINTORES CONTRA INCENDIO'],
        ['EJECUTÓ', servicio.user?.name || '-'],
        ['REVISÓ', 'JOSE LUIS SANTIAGO MAZA'],
        ['FECHA', dateLabel(servicio.dateStart)],
        ['SERVICIO', `MANTENIMIENTO #${servicio.id}`],
    ])

    section(doc, 2, 'CARACTERÍSTICAS DE LOS EXTINTORES CONTRA INCENDIOS', 227)
    keyValueTable(doc, leftX, 242, halfW, [
        ['CÓDIGO DE ID.', e.codeExtintor],
        ['UBICACIÓN', e.location],
        ['TIPO DE EXTINTOR', e.type],
        ['PRESIÓN', e.pressure],
        ['CAPACIDAD', e.capacity],
        ['RATING', e.rating],
    ])
    keyValueTable(doc, leftX + halfW + halfGap, 242, halfW, [
        ['MARCA', e.brand],
        ['MODELO', e.model],
        ['N° DE SERIE', e.serialNumberNFC || e.cylinderNumber],
        ['AÑO FABRICACIÓN', e.yearManufacture],
        ['FECHA P.H.', dateLabel(e.dateHydrostatic)],
        ['FECHA PRÓXIMA P.H.', e.dateHydrostatic ? String(new Date(e.dateHydrostatic).getFullYear() + 5) : '-'],
    ])

    section(doc, 3, 'REVISIÓN DE LOS COMPONENTES DEL EXTINTOR CONTRA INCENDIOS', 373)
    doc.font('Helvetica-Bold').fontSize(5).fillColor('#B00000').text(
        inspectionServiceId
            ? `ÚLTIMA INSPECCIÓN #${inspectionServiceId}: ${fullDateLabel(inspectionDate)}`
            : 'SIN INSPECCIÓN REGISTRADA',
        410, 372, { width: 165, align: 'right' },
    )
    doc.font('Helvetica').fontSize(4.5).fillColor('#111111').text(
        inspectionServiceId ? inspectionObservation : '',
        410, 380, { width: 165, align: 'right', ellipsis: true },
    )
    componentTable(doc, leftX, 389, [
        { part: 'CILINDRO', checks: [
            { label: 'Corrosión', value: inspection?.estado },
            { label: 'Daños en superficie', value: inspection?.estado },
            { label: 'Hilos de rosca dañadas', value: inspection?.estado },
            { label: 'Soldadura', value: inspection?.estado },
            { label: 'Pintura dañada', value: inspection?.estado },
            { label: 'Daños en soporte', value: inspection?.soporte },
        ] },
        { part: 'MANÓMETRO', checks: [
            { label: 'Golpeado o malogrado', value: inspection?.presion },
            { label: 'Corrosión', value: inspection?.presion },
            { label: 'Dial o carátula ilegible', value: inspection?.presion },
        ] },
        { part: 'MANGUERA', checks: [
            { label: 'Dañada', value: inspection?.manguera },
            { label: 'Cuarteada o rota', value: inspection?.manguera },
        ] },
        { part: 'PQS', checks: [
            { label: 'Grumoso', value: inspection?.carga },
            { label: 'Compacto', value: inspection?.carga },
            { label: 'Descargado', value: inspection?.carga },
        ] },
    ])
    componentTable(doc, leftX + halfW + halfGap, 389, [
        { part: 'PISTOLA O\nVÁLVULA DE\nSALIDA', checks: [
            { label: 'Palanca dañada', value: inspection?.activacion },
            { label: 'Boquilla obstruida', value: inspection?.boquilla },
            { label: 'Rosca o hilos dañados', value: inspection?.estado },
            { label: 'O-ring defectuoso', value: inspection?.estado },
            { label: 'Retén de vástago', value: inspection?.seguridad },
            { label: 'Vástago dañado', value: inspection?.activacion },
        ] },
        { part: 'CARTUCHO\nIMPULSOR', checks: [
            { label: 'Sello roscado dañado', value: inspection?.seguridad },
            { label: 'Hilos de rosca dañadas', value: inspection?.estado },
            { label: 'Asiento del sello dañado', value: inspection?.seguridad },
        ] },
        { part: 'MECANISMO DE\nPERFORACIÓN', checks: [
            { label: 'Perforador dañado', value: inspection?.activacion },
            { label: 'Corrosión', value: inspection?.estado },
        ] },
        { part: 'CORNETA O\nTOBERA', checks: [
            { label: 'Deformada, dañada, rajada', value: inspection?.boquilla },
            { label: 'Salida obstruida', value: inspection?.boquilla },
            { label: 'Daño en hilos de uniones', value: inspection?.boquilla },
        ] },
    ])

    section(doc, 4, 'SERVICIOS REALIZADOS', 650)
    doc.font('Helvetica').fontSize(7).text(serviceText(md), 45, 670, { width: 430 })
    doc.moveTo(43, 686).lineTo(578, 686).stroke()

    section(doc, 5, 'CAMBIO DE COMPONENTES', 704)
    doc.font('Helvetica').fontSize(7).text(md?.detallesCambioPartes || 'NINGUNO.', 45, 724, { width: 430 })
    doc.moveTo(43, 740).lineTo(578, 740).stroke()

    section(doc, 6, 'OBSERVACIONES', 760)
    doc.font('Helvetica-Bold').fontSize(7).text(
        servicioExtintor.observaciones || `MANTENIMIENTO #${servicio.id}`,
        195,
        760,
        { width: 380 },
    )
    doc.moveTo(195, 776).lineTo(578, 776).stroke()

    doc.font('Helvetica').fontSize(5).text(
        'La información en este formulario cubre los requerimientos de la norma NFPA 10 y la NTP 350.043: Selección y Distribución de Extintores Portátiles.',
        22,
        810,
        { width: 550, align: 'center' },
    )
}

export const ReporteMantenimientoAnualController = {
    async listar(req, res) {
        try {
            const servicioId = req.params.servicioId ? Number(req.params.servicioId) : null
            if (req.params.servicioId && !Number.isInteger(servicioId)) {
                return res.status(400).json({ ok: false, message: 'servicioId inválido' })
            }
            const servicios = await ReporteMantenimientoAnualService.listar(servicioId)
            if (servicioId && !servicios.length) {
                return res.status(404).json({ ok: false, message: 'Servicio de mantenimiento no encontrado' })
            }
            return res.json({ ok: true, total: servicios.length, servicios })
        } catch (error) {
            console.error(error)
            return res.status(500).json({ ok: false, message: 'Error al listar mantenimientos anuales' })
        }
    },

    async descargar(req, res) {
        try {
            const servicioId = req.params.servicioId ? Number(req.params.servicioId) : null
            if (req.params.servicioId && !Number.isInteger(servicioId)) {
                return res.status(400).json({ message: 'servicioId inválido' })
            }
            const servicios = await ReporteMantenimientoAnualService.listar(servicioId)
            if (servicioId && !servicios.length) {
                return res.status(404).json({ message: 'Servicio de mantenimiento no encontrado' })
            }
            const fichas = servicios.flatMap((servicio) =>
                servicio.servicioExtintores.map((servicioExtintor) => ({ servicio, servicioExtintor })))

            if (!fichas.length) return res.status(404).json({ message: 'No existen mantenimientos para generar' })

            const doc = new PDFDocument({ size: 'A4', margin: 0, autoFirstPage: false })
            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
            res.setHeader('Pragma', 'no-cache')
            res.setHeader('Expires', '0')
            const filename = servicioId
                ? `mantenimiento-anual-servicio-${servicioId}.pdf`
                : 'mantenimientos-anuales.pdf'
            res.setHeader('Content-Disposition', `attachment; filename=${filename}`)
            doc.pipe(res)

            fichas.forEach(({ servicio, servicioExtintor }, index) => {
                doc.addPage({ size: 'A4', margin: 0 })
                drawPage(doc, servicio, servicioExtintor, index, fichas.length)
            })
            doc.end()
        } catch (error) {
            console.error(error)
            if (!res.headersSent) res.status(500).json({ message: 'Error al generar mantenimientos anuales' })
        }
    },
}
