import PDFDocument from 'pdfkit'
import ExcelJS from 'exceljs'
import path from 'path'
import { ReporteInspeccionMensualService } from '../../service/reporte/inspeccionMensual.service.js'

const PAGE_MARGIN = 26
const HEADER_Y = 118
const HEADER_HEIGHT = 105
const ROW_HEIGHT = 29

const columns = [
    { key: 'numero', label: 'N°', width: 17 },
    { key: 'codigo', label: 'Código /\nTag', width: 42 },
    { key: 'capacidad', label: 'Capac.', width: 38 },
    { key: 'tipo', label: 'Tipo /\nClase', width: 39 },
    { key: 'claseRating', label: 'Rating', width: 38 },
    { key: 'presionEquipo', label: 'Presión', width: 47 },
    { key: 'marca', label: 'Marca', width: 43 },
    { key: 'modelo', label: 'Modelo', width: 45 },
    { key: 'numeroSerie', label: 'N° Serie', width: 43 },
    { key: 'numeroCilindro', label: 'N° Cilindro', width: 45 },
    { key: 'anioFabricacion', label: 'Año de\nFab.', width: 34 },
    { key: 'ph', label: 'P.H.', width: 35 },
    { key: 'ubicacionEquipo', label: 'Ubicación', width: 72 },
    { key: 'fechaVencMantto', label: 'Fecha Venc. Mantto.', width: 38, vertical: true },
    { key: 'fechaPruebaHidro', label: 'Fecha prueba Hidrost.', width: 38, vertical: true },
    { key: 'numeroMantenimiento', label: 'Número de Mantenimiento', width: 25, vertical: true },
    { key: 'ubicadoNumeracion', label: 'Ubicado con numeración', width: 25, vertical: true },
    { key: 'accesoLibre', label: 'Acceso libre de obstáculos', width: 25, vertical: true },
    { key: 'alturaAdecuada', label: 'Ubicado en altura adecuada', width: 25, vertical: true },
    { key: 'pictogramaUso', label: 'Pictograma de acuerdo al uso', width: 25, vertical: true },
    { key: 'pictogramaClase', label: 'Pictograma de clase de fuego', width: 25, vertical: true },
    { key: 'manometro', label: 'Manómetro en presión correcta', width: 25, vertical: true },
    { key: 'precinto', label: 'Cuenta con precinto de seguridad', width: 25, vertical: true },
    { key: 'cilindroEstado', label: 'Cilindro en buenas condiciones', width: 25, vertical: true },
    { key: 'indicaAgente', label: 'Indica agente extintor', width: 25, vertical: true },
    { key: 'colgador', label: 'Colgador adecuado y seguro', width: 25, vertical: true },
    { key: 'manija', label: 'Manija de acarreo en buen estado', width: 25, vertical: true },
    { key: 'manguera', label: 'Manguera en buenas condiciones', width: 25, vertical: true },
    { key: 'tobera', label: 'Tobera, pitón o pistola en buenas condiciones', width: 25, vertical: true },
    { key: 'sujetador', label: 'Sujetador en buenas condiciones', width: 25, vertical: true },
    { key: 'observaciones', label: 'Observaciones', width: 135 },
]

const tableWidth = columns.reduce((sum, column) => sum + column.width, 0)

function formatMonth(value) {
    if (!value) return '-'
    const localMatch = String(value).match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})/)
    const date = localMatch
        ? new Date(Number(localMatch[3]), Number(localMatch[2]) - 1, Number(localMatch[1]))
        : new Date(value)
    if (Number.isNaN(date.getTime())) return '-'
    return date.toLocaleDateString('es-PE', { month: 'long' }).toUpperCase()
}

function formatDate(value) {
    if (!value) return '-'
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return '-'
    return date.toLocaleDateString('es-PE', { month: 'short', year: '2-digit' }).toUpperCase()
}

function normalizeChecklist(value) {
    if (!value) return 'N/A'
    const normalized = String(value).trim().toUpperCase()
    if (['OK', 'C', 'CUMPLE', 'SI', 'SÍ', 'BUENO'].includes(normalized)) return 'C'
    if (['NO', 'NC', 'NO CUMPLE', 'MALO', 'OBSERVADO'].includes(normalized)) return 'NC'
    return normalized
}

function drawHeader(doc, reporte, pageNumber, totalPages) {
    const logoPath = path.resolve('uploads/logo.png')
    try {
        doc.image(logoPath, PAGE_MARGIN + 4, 22, { width: 74 })
    } catch {
        // El reporte continúa aunque el logo no esté disponible.
    }

    doc.fillColor('#222222').font('Helvetica-Bold').fontSize(7)
    doc.text('Organización Iberoamericana\nde Seguridad contra Incendios', PAGE_MARGIN + 84, 31, {
        width: 155,
        lineGap: 1,
    })

    doc.fillColor('#c00000').font('Helvetica-Bold').fontSize(14)
    doc.text('INSPECCIÓN MENSUAL DE EXTINTORES\nCONTRA INCENDIOS', 270, 28, {
        width: 300,
        align: 'center',
        lineGap: 1,
    })

    doc.fillColor('#111111').font('Helvetica').fontSize(5.5)
    doc.text('Revisión: 05\nVigencia: 08.08.24\nPágina ' + pageNumber + ' de ' + totalPages, doc.page.width - 105, 27, {
        width: 78,
        align: 'right',
    })

    const metaY = 70
    const meta = [
        ['EMPRESA:', reporte.empresa || '-'],
        ['INSTALACIÓN:', reporte.instalacion || '-'],
        ['RESPONSABLE:', reporte.responsable || '-'],
        ['MES:', formatMonth(reporte.mes)],
    ]
    const metaX = [PAGE_MARGIN, 310, 650, doc.page.width - 165]
    const valueWidths = [205, 230, 165, 105]

    meta.forEach(([label, value], index) => {
        doc.font('Helvetica-Bold').fontSize(5.5).text(label, metaX[index], metaY)
        doc.font('Helvetica').text(String(value), metaX[index] + 58, metaY, {
            width: valueWidths[index],
            ellipsis: true,
            lineBreak: false,
        })
    })

    doc.font('Helvetica-Bold').fontSize(4.5)
    doc.text('C: Cumple / NC: No Cumple / N.A: No Aplica', PAGE_MARGIN, 94)
}

function drawTableHeader(doc) {
    let x = PAGE_MARGIN
    doc.lineWidth(0.5).strokeColor('#111111')

    columns.forEach((column) => {
        doc.save()
        doc.rect(x, HEADER_Y, column.width, HEADER_HEIGHT).fillAndStroke('#d9d9d9', '#111111')
        doc.fillColor('#111111').font('Helvetica-Bold')

        if (column.vertical) {
            doc.translate(x + (column.width / 2) + 2, HEADER_Y + HEADER_HEIGHT - 5)
            doc.rotate(-90)
            doc.fontSize(5.2).text(column.label, 0, 0, {
                width: HEADER_HEIGHT - 10,
                height: column.width - 4,
                align: 'left',
                ellipsis: true,
                lineBreak: false,
            })
        } else {
            doc.fontSize(5.6).text(column.label, x + 2, HEADER_Y + (HEADER_HEIGHT / 2) - 7, {
                width: column.width - 4,
                height: 28,
                align: 'center',
                ellipsis: true,
            })
        }
        doc.restore()
        x += column.width
    })
}

function drawDataRow(doc, y, item) {
    let x = PAGE_MARGIN
    const row = {
        ...item,
        ph: formatDate(item.ph),
        fechaVencMantto: formatDate(item.fechaVencMantto),
        fechaPruebaHidro: formatDate(item.fechaPruebaHidro),
        numeroMantenimiento: 1,
    }

    const checklistKeys = new Set([
        'ubicadoNumeracion', 'accesoLibre', 'alturaAdecuada', 'pictogramaUso',
        'pictogramaClase', 'manometro', 'precinto', 'cilindroEstado', 'indicaAgente',
        'colgador', 'manija', 'manguera', 'tobera', 'sujetador',
    ])

    columns.forEach((column) => {
        const rawValue = checklistKeys.has(column.key)
            ? normalizeChecklist(row[column.key])
            : (row[column.key] ?? '-')

        doc.rect(x, y, column.width, ROW_HEIGHT).stroke('#111111')
        doc.save()
        doc.rect(x + 1, y + 1, column.width - 2, ROW_HEIGHT - 2).clip()
        doc.fillColor('#111111').font('Helvetica').fontSize(column.key === 'observaciones' ? 5.2 : 5.5)
        doc.text(String(rawValue), x + 2, y + 8, {
            width: column.width - 4,
            height: ROW_HEIGHT - 10,
            align: column.key === 'observaciones' ? 'left' : 'center',
            ellipsis: true,
        })
        doc.restore()
        x += column.width
    })
}

function buildExcelRow(item) {
    const checklistKeys = new Set([
        'ubicadoNumeracion', 'accesoLibre', 'alturaAdecuada', 'pictogramaUso',
        'pictogramaClase', 'manometro', 'precinto', 'cilindroEstado', 'indicaAgente',
        'colgador', 'manija', 'manguera', 'tobera', 'sujetador',
    ])
    const row = {
        ...item,
        ph: formatDate(item.ph),
        fechaVencMantto: formatDate(item.fechaVencMantto),
        fechaPruebaHidro: formatDate(item.fechaPruebaHidro),
        numeroMantenimiento: 1,
    }

    return columns.map((column) => {
        const value = checklistKeys.has(column.key)
            ? normalizeChecklist(row[column.key])
            : row[column.key]
        return value ?? '-'
    })
}

function styleExcelRange(worksheet, startRow, endRow, startColumn, endColumn, style) {
    for (let row = startRow; row <= endRow; row += 1) {
        for (let column = startColumn; column <= endColumn; column += 1) {
            Object.assign(worksheet.getCell(row, column), style)
        }
    }
}

async function crearExcelMensual(reporte) {
    const workbook = new ExcelJS.Workbook()
    workbook.creator = 'OISCI'
    workbook.created = new Date()

    const worksheet = workbook.addWorksheet('Inspección Mensual', {
        views: [{ showGridLines: false, state: 'frozen', ySplit: 8, xSplit: 2 }],
        pageSetup: {
            orientation: 'landscape',
            paperSize: 9,
            fitToPage: true,
            fitToWidth: 1,
            fitToHeight: 0,
            margins: { left: 0.2, right: 0.2, top: 0.3, bottom: 0.3, header: 0.1, footer: 0.1 },
            printTitlesRow: '1:8',
        },
        properties: { defaultRowHeight: 18 },
    })

    worksheet.pageSetup.printArea = `A1:AE${Math.max(9, 8 + reporte.equipos.length)}`

    columns.forEach((column, index) => {
        worksheet.getColumn(index + 1).width = Math.max(4, column.width / 5.8)
    })

    worksheet.mergeCells('E1:AA3')
    const titleCell = worksheet.getCell('E1')
    titleCell.value = 'INSPECCIÓN MENSUAL DE EXTINTORES\nCONTRA INCENDIOS'
    titleCell.font = { name: 'Arial', size: 16, bold: true, color: { argb: 'FFC00000' } }
    titleCell.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true }

    worksheet.mergeCells('A1:D3')
    try {
        const logoId = workbook.addImage({ filename: path.resolve('uploads/logo.png'), extension: 'png' })
        worksheet.addImage(logoId, { tl: { col: 0.15, row: 0.15 }, ext: { width: 115, height: 42 } })
    } catch {
        worksheet.getCell('A1').value = 'OISCI'
        worksheet.getCell('A1').font = { size: 18, bold: true }
    }

    worksheet.mergeCells('AB1:AE3')
    const revisionCell = worksheet.getCell('AB1')
    revisionCell.value = 'Revisión: 05\nVigencia: 08.08.24\nPágina 1'
    revisionCell.font = { name: 'Arial', size: 7 }
    revisionCell.alignment = { horizontal: 'right', vertical: 'middle', wrapText: true }

    const meta = [
        ['A4', 'D4', 'EMPRESA:', reporte.empresa || '-'],
        ['E4', 'L4', 'INSTALACIÓN:', reporte.instalacion || '-'],
        ['M4', 'V4', 'RESPONSABLE:', reporte.responsable || '-'],
        ['W4', 'AE4', 'MES:', formatMonth(reporte.mes)],
    ]
    meta.forEach(([start, end, label, value]) => {
        worksheet.mergeCells(`${start}:${end}`)
        const cell = worksheet.getCell(start)
        cell.value = `${label}  ${value}`
        cell.font = { name: 'Arial', size: 8, bold: true }
        cell.alignment = { vertical: 'middle', wrapText: false }
    })

    worksheet.mergeCells('A6:AE6')
    worksheet.getCell('A6').value = 'C: Cumple / NC: No Cumple / N.A: No Aplica'
    worksheet.getCell('A6').font = { name: 'Arial', size: 7, bold: true }

    const headerRow = worksheet.getRow(8)
    headerRow.height = 105
    columns.forEach((column, index) => {
        const cell = headerRow.getCell(index + 1)
        cell.value = column.label.replaceAll('\n', ' ')
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD9D9D9' } }
        cell.font = { name: 'Arial', size: 7, bold: true }
        cell.alignment = {
            horizontal: 'center',
            vertical: 'middle',
            wrapText: true,
            textRotation: column.vertical ? 90 : 0,
        }
        cell.border = {
            top: { style: 'thin', color: { argb: 'FF333333' } },
            left: { style: 'thin', color: { argb: 'FF333333' } },
            bottom: { style: 'thin', color: { argb: 'FF333333' } },
            right: { style: 'thin', color: { argb: 'FF333333' } },
        }
    })

    const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []
    equipos.forEach((item, index) => {
        const row = worksheet.getRow(index + 9)
        row.values = buildExcelRow(item)
        row.height = 32
        row.eachCell({ includeEmpty: true }, (cell, columnNumber) => {
            cell.font = { name: 'Arial', size: 7 }
            cell.alignment = {
                horizontal: columnNumber === columns.length ? 'left' : 'center',
                vertical: 'middle',
                wrapText: true,
            }
            cell.border = {
                top: { style: 'thin', color: { argb: 'FF555555' } },
                left: { style: 'thin', color: { argb: 'FF555555' } },
                bottom: { style: 'thin', color: { argb: 'FF555555' } },
                right: { style: 'thin', color: { argb: 'FF555555' } },
            }
        })
    })

    styleExcelRange(worksheet, 1, 6, 1, columns.length, {
        fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFFFFF' } },
    })
    worksheet.getRow(1).height = 24
    worksheet.getRow(2).height = 22
    worksheet.getRow(3).height = 22
    worksheet.getRow(4).height = 24
    worksheet.getRow(6).height = 18

    return workbook
}

export const ReporteInspeccionMensualController = {
    async obtener(req, res) {
        try {
            const { servicioId } = req.params
            if (!servicioId) return res.status(400).json({ ok: false, message: 'servicioId es requerido' })

            const reporte = await ReporteInspeccionMensualService.generar(Number(servicioId))
            if (!reporte) return res.status(404).json({ ok: false, message: 'Servicio no encontrado' })

            return res.status(200).json({ ok: true, reporte: [reporte] })
        } catch (error) {
            console.error(error)
            return res.status(500).json({ ok: false, message: 'Error al obtener reporte de inspección mensual' })
        }
    },

    async descargar(req, res) {
        try {
            const { servicioId } = req.params
            const reporte = await ReporteInspeccionMensualService.generar(Number(servicioId))
            if (!reporte) return res.status(404).json({ message: 'Servicio no encontrado' })

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []
            const rowsPerPage = 11
            const totalPages = Math.max(1, Math.ceil(equipos.length / rowsPerPage))
            const doc = new PDFDocument({
                size: [tableWidth + (PAGE_MARGIN * 2), 595.28],
                layout: 'portrait',
                margin: 0,
                autoFirstPage: false,
            })

            res.setHeader('Content-Type', 'application/pdf')
            res.setHeader('Content-Disposition', `attachment; filename=inspeccion-mensual-${servicioId}.pdf`)
            doc.pipe(res)

            for (let pageIndex = 0; pageIndex < totalPages; pageIndex += 1) {
                doc.addPage({ size: [tableWidth + (PAGE_MARGIN * 2), 595.28], margin: 0 })
                drawHeader(doc, reporte, pageIndex + 1, totalPages)
                drawTableHeader(doc)

                const pageRows = equipos.slice(pageIndex * rowsPerPage, (pageIndex + 1) * rowsPerPage)
                pageRows.forEach((item, rowIndex) => {
                    drawDataRow(doc, HEADER_Y + HEADER_HEIGHT + (rowIndex * ROW_HEIGHT), item)
                })
            }

            doc.end()
        } catch (error) {
            console.error(error)
            if (!res.headersSent) res.status(500).json({ message: 'Error al generar PDF mensual' })
        }
    },

    async descargarExcel(req, res) {
        try {
            const { servicioId } = req.params
            const reporte = await ReporteInspeccionMensualService.generar(Number(servicioId))
            if (!reporte) return res.status(404).json({ message: 'Servicio no encontrado' })

            const workbook = await crearExcelMensual(reporte)
            res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            res.setHeader('Content-Disposition', `attachment; filename=inspeccion-mensual-${servicioId}.xlsx`)
            await workbook.xlsx.write(res)
            res.end()
        } catch (error) {
            console.error(error)
            if (!res.headersSent) res.status(500).json({ message: 'Error al generar Excel mensual' })
        }
    },
}
