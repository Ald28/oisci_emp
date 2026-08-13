import PDFDocument from "pdfkit";
import axios from "axios";
import path from "path";
import fs from "fs/promises";
import ExcelJS from "exceljs";
import { obtenerKeyDesdeS3Url } from "./storage/keyS3.js";
import {
  getExtintoresFull,
  getData,
  getDataByServiceId,
} from "../../repository/inpeccionD/extintor.repository.js";

const buildPreviewUrl = (url) => {
  if (!url) return null;

  const key = obtenerKeyDesdeS3Url(url);
  return `${process.env.API_URL}/certificado/preview?key=${encodeURIComponent(key)}`;
};

const formatDate = (value) => {
  if (!value) return "";
  const date = new Date(value);
  return date.toLocaleDateString("es-PE");
};

const combineObservaciones = (ext) => {
  return [
    ...ext.serviciosExtintor.map((s) => s.observaciones).filter(Boolean),
    ...ext.serviciosExtintor
      .map((s) => s.inspeccionDetalle?.observaciones)
      .filter(Boolean),
    ...ext.serviciosExtintor
      .map((s) => s.mantenimientoDetalle?.detallesCambioPartes)
      .filter(Boolean),
  ].join(" | ");
};

export const getExtintores = async () => {
  const data = await getExtintoresFull();

  return data.map((ext) => ({
    id: ext.id,
    codeExtintor: ext.codeExtintor,
    photo: buildPreviewUrl(ext.photo),

    cliente: ext.sede?.client?.razonSocial,
    sede: ext.sede?.name_sede,

    inspecciones: ext.serviciosExtintor
      .filter((s) => s.inspeccionDetalle && s.servicio?.type === "INSPECCION")
      .map((s) => ({
        fotos: [
          s.inspeccionDetalle.foto1Url,
          s.inspeccionDetalle.foto2Url,
          s.inspeccionDetalle.foto3Url,
          s.inspeccionDetalle.foto4Url,
        ]
          .map((url) => buildPreviewUrl(url))
          .filter(Boolean),

        observacionesDetalle: s.inspeccionDetalle.observaciones,

        observacionesServicio: s.observaciones,

        fecha: s.servicio?.dateStart,
      })),
  }));
};

export const getExtintoresPDF = async () => {
  const data = await getData();

  return data.map((ext) => ({
    id: ext.id,
    codigo: ext.codeExtintor,
    tipo: ext.type,
    capacidad: ext.capacity,
    foto: buildPreviewUrl(ext.photo),

    empresa: ext.sede?.client?.razonSocial,
    sede: ext.sede?.name_sede,

    mantenimientos: ext.serviciosExtintor
      .filter(
        (s) => s.servicio?.type === "MANTENIMIENTO" && s.mantenimientoDetalle,
      )
      .map((s) => ({
        fecha: s.servicio.dateStart,

        checklist: {
          mantenimiento: s.mantenimientoDetalle.mantenimiento,
          recarga: s.mantenimientoDetalle.recarga,
          agenteCarga: s.mantenimientoDetalle.agenteCarga,
          pruebaHidrostatica: s.mantenimientoDetalle.pruebaHidrostatica,
          pintura: s.mantenimientoDetalle.pintura,
          cambioPartes: s.mantenimientoDetalle.cambioPartes,
        },

        observaciones: s.observaciones || null,
      })),

    inspecciones: ext.serviciosExtintor
      .filter((s) => s.servicio?.type === "INSPECCION" && s.inspeccionDetalle)
      .map((s) => ({
        fecha: s.servicio.dateStart,

        checklist: {
          ubicacion: s.inspeccionDetalle.ubicacion,
          accesibilidad: s.inspeccionDetalle.accesibilidad,
          instalacion: s.inspeccionDetalle.instalacion,
          instrucciones: s.inspeccionDetalle.instrucciones,
          clasificacion: s.inspeccionDetalle.clasificacion,
          recarga: s.inspeccionDetalle.recarga,
          certificacion: s.inspeccionDetalle.certificacion,
          presion: s.inspeccionDetalle.presion,
          seguridad: s.inspeccionDetalle.seguridad,
          estado: s.inspeccionDetalle.estado,
          carga: s.inspeccionDetalle.carga,
          soporte: s.inspeccionDetalle.soporte,
          activacion: s.inspeccionDetalle.activacion,
          manguera: s.inspeccionDetalle.manguera,
          boquilla: s.inspeccionDetalle.boquilla,
          abrazadera: s.inspeccionDetalle.abrazadera,
        },

        fotos: [
          s.inspeccionDetalle.foto1Url,
          s.inspeccionDetalle.foto2Url,
          s.inspeccionDetalle.foto3Url,
          s.inspeccionDetalle.foto4Url,
        ]
          .map((url) => buildPreviewUrl(url))
          .filter(Boolean),

        observaciones: s.inspeccionDetalle.observaciones,
      })),
  }));
};

const getExportData = async (serviceId) => {
  if (serviceId) {
    return getDataByServiceId(serviceId);
  }
  return getData();
};

export const getExtintoresExcel = async (extintorId, serviceId) => {
  const data = await getExportData(serviceId);
  const extintores = extintorId
    ? data.filter((ext) => ext.id === Number(extintorId))
    : data;

  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet("Extintores");

  worksheet.columns = [
    { header: "CÓDIGO EXTINTOR", key: "codeExtintor", width: 20 },
    { header: "SERIAL NFC", key: "serialNumberNFC", width: 20 },
    { header: "TIPO", key: "type", width: 16 },
    { header: "CAPACIDAD", key: "capacity", width: 16 },
    { header: "RATING", key: "rating", width: 16 },
    { header: "PRESIÓN", key: "pressure", width: 18 },
    { header: "MARCA", key: "brand", width: 18 },
    { header: "MODELO", key: "model", width: 18 },
    { header: "NÚMERO CILINDRO", key: "cylinderNumber", width: 18 },
    { header: "AÑO FABRICACIÓN", key: "yearManufacture", width: 16 },
    { header: "UBICACIÓN", key: "location", width: 20 },
    { header: "FECHA HIDROSTÁTICA", key: "dateHydrostatic", width: 20 },
    { header: "FECHA MANTENIMIENTO", key: "dateMaintenance", width: 20 },
    { header: "FECHA RECARGA", key: "rechargeDate", width: 20 },
    { header: "FECHA BAJA", key: "dateLow", width: 20 },
    { header: "EMPRESA", key: "empresa", width: 24 },
    { header: "SEDE", key: "sede", width: 20 },
    { header: "OBSERVACIONES", key: "observaciones", width: 36 },
  ];

  let headerRow = 1;
  if (serviceId) {
    const empresa = extintores[0]?.sede?.client?.razonSocial || "";
    const primerServicio = extintores
      .flatMap((e) => e.serviciosExtintor || [])
      .find((s) => s?.servicio?.dateStart);
    const mes = primerServicio?.servicio?.dateStart
      ? new Date(primerServicio.servicio.dateStart).toLocaleDateString("es-PE", {
          month: "long",
        })
      : "";

    // Desplazar la cabecera/tabla hacia abajo para agregar metadata.
    worksheet.spliceRows(1, 0, [], [], [], []);
    headerRow = 5;

    worksheet.mergeCells("A1:H1");
    worksheet.getCell("A1").value = `CLIENTE: ${empresa}`;
    worksheet.getCell("A1").font = { bold: true, size: 12 };

    worksheet.mergeCells("A2:H2");
    worksheet.getCell("A2").value = `MES: ${mes ? mes.toUpperCase() : ""}`;
    worksheet.getCell("A2").font = { bold: true, size: 12 };

    try {
      const logoBuffer = await fs.readFile(path.resolve("uploads/logo.png"));
      const logoId = workbook.addImage({
        buffer: logoBuffer,
        extension: "png",
      });
      worksheet.addImage(logoId, {
        tl: { col: 14.5, row: 0 },
        ext: { width: 140, height: 45 },
      });
    } catch (error) {
      // ignore missing logo
    }
  }

  extintores.forEach((ext) => {
    worksheet.addRow({
      codeExtintor: ext.codeExtintor || "",
      serialNumberNFC: ext.serialNumberNFC || "",
      type: ext.type || "",
      capacity: ext.capacity || "",
      rating: ext.rating || "",
      pressure: ext.pressure || "",
      brand: ext.brand || "",
      model: ext.model || "",
      cylinderNumber: ext.cylinderNumber || "",
      yearManufacture: ext.yearManufacture || "",
      location: ext.location || "",
      dateHydrostatic: formatDate(ext.dateHydrostatic),
      dateMaintenance: formatDate(ext.dateMaintenance),
      rechargeDate: formatDate(ext.rechargeDate),
      dateLow: formatDate(ext.dateLow),
      empresa: ext.sede?.client?.razonSocial || "",
      sede: ext.sede?.name_sede || "",
      observaciones: combineObservaciones(ext),
    });
  });

  for (let rowNumber = headerRow; rowNumber <= worksheet.rowCount; rowNumber += 1) {
    const row = worksheet.getRow(rowNumber);
    row.eachCell((cell) => {
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" },
      };
      cell.alignment = { vertical: "middle", horizontal: "left", wrapText: true };
    });
  }

  worksheet.getRow(headerRow).font = { bold: true };
  worksheet.properties.defaultRowHeight = 20;

  const buffer = await workbook.xlsx.writeBuffer();

  return {
    fileName: `extintores-${new Date().toISOString().slice(0, 10)}.xlsx`,
    buffer,
  };
};

export const getExtintoresPdfBuffer = async (extintorId, serviceId) => {
  const data = await getExportData(serviceId);
  const extintores = extintorId
    ? data.filter((ext) => ext.id === Number(extintorId))
    : data;

  const doc = new PDFDocument({ margin: 10, size: "A4", layout: "landscape" });
  const chunks = [];

  doc.on("data", (chunk) => chunks.push(chunk));

  const pdfReady = new Promise((resolve, reject) => {
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);
  });

  const columns = [
    { header: "CÓDIGO EXTINTOR", key: "codeExtintor", width: 50 },
    { header: "SERIAL NFC", key: "serialNumberNFC", width: 55 },
    { header: "TIPO", key: "type", width: 45 },
    { header: "CAPACIDAD", key: "capacity", width: 45 },
    { header: "RATING", key: "rating", width: 45 },
    { header: "PRESIÓN", key: "pressure", width: 50 },
    { header: "MARCA", key: "brand", width: 50 },
    { header: "MODELO", key: "model", width: 50 },
    { header: "NÚMERO CILINDRO", key: "cylinderNumber", width: 55 },
    { header: "AÑO FABRICACIÓN", key: "yearManufacture", width: 40 },
    { header: "UBICACIÓN", key: "location", width: 55 },
    { header: "FECHA HIDROSTÁTICA", key: "dateHydrostatic", width: 55 },
    { header: "FECHA MANTENIMIENTO", key: "dateMaintenance", width: 55 },
    { header: "FECHA RECARGA", key: "rechargeDate", width: 55 },
    { header: "FECHA BAJA", key: "dateLow", width: 45 },
    { header: "EMPRESA", key: "empresa", width: 65 },
    { header: "SEDE", key: "sede", width: 60 },
    { header: "OBSERVACIONES", key: "observaciones", width: 95 },
  ];

  const startX = doc.page.margins.left;
  const usableWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const rowHeight = 22;
  const headerHeight = 20;
  const bottomMargin = doc.page.height - doc.page.margins.bottom;
  let y = doc.y + 10;

  const cliente = extintores[0]?.sede?.client?.razonSocial || "";
  const primerServicio = extintores
    .flatMap((e) => e.serviciosExtintor || [])
    .find((s) => s?.servicio?.dateStart);
  const mes = primerServicio?.servicio?.dateStart
    ? new Date(primerServicio.servicio.dateStart).toLocaleDateString("es-PE", {
      month: "long",
    }).toUpperCase()
    : "";

  const drawExportHeader = () => {
    if (!serviceId) {
      doc.font("Helvetica-Bold").fontSize(12).text("Reporte de Extintores", startX, y, { align: "left" });
      y += 18;
      return;
    }

    doc.font("Helvetica-Bold").fontSize(12).text(`CLIENTE: ${cliente}`, startX, y, { align: "left" });
    y += 16;
    doc.font("Helvetica-Bold").fontSize(12).text(`MES: ${mes}`, startX, y, { align: "left" });

    try {
      const logoPath = path.resolve("uploads/logo.png");
      doc.image(logoPath, doc.page.width - doc.page.margins.right - 120, y - 16, { width: 110 });
    } catch (error) {
      // ignore missing logo
    }

    y += 26;
  };

  const formatCellValue = (ext, key) => {
    if (key === "serialNumberNFC") {
      return ext.serialNumberNFC || ext.cylinderNumber || "";
    }
    if (key === "dateHydrostatic") return formatDate(ext.dateHydrostatic);
    if (key === "dateMaintenance") return formatDate(ext.dateMaintenance);
    if (key === "rechargeDate") return formatDate(ext.rechargeDate);
    if (key === "dateLow") return formatDate(ext.dateLow);
    if (key === "empresa") return ext.sede?.client?.razonSocial || "";
    if (key === "sede") return ext.sede?.name_sede || "";
    if (key === "observaciones") return combineObservaciones(ext) || "";
    return ext[key] ?? "";
  };

  const drawTableHeader = () => {
    let x = startX;
    doc.font("Helvetica-Bold").fontSize(7.5).fillColor("black");
    columns.forEach((column) => {
      doc.rect(x, y, column.width, headerHeight).stroke();
      doc.text(column.header, x + 2, y + 4, {
        width: column.width - 4,
        align: "left",
        lineBreak: true,
        ellipsis: true,
      });
      x += column.width;
    });
    y += headerHeight;
  };

  const drawRow = (ext) => {
    let x = startX;
    const cellY = y;
    doc.font("Helvetica").fontSize(7.5).fillColor("black");
    columns.forEach((column) => {
      const text = formatCellValue(ext, column.key);
      doc.rect(x, cellY, column.width, rowHeight).stroke();
      doc.text(text, x + 2, cellY + 3, {
        width: column.width - 4,
        align: "left",
        lineBreak: true,
        ellipsis: true,
        height: rowHeight - 6,
      });
      x += column.width;
    });
    y += rowHeight;
  };

  drawExportHeader();
  drawTableHeader();

  extintores.forEach((ext) => {
    if (y + rowHeight > bottomMargin) {
      doc.addPage({ margin: 10, size: "A4", layout: "landscape" });
      y = doc.y + 10;
      drawTableHeader();
    }
    drawRow(ext);
  });

  doc.end();
  return pdfReady;
};

export default {
  getExtintores,
  getExtintoresPDF,
  getExtintoresExcel,
  getExtintoresPdfBuffer,
};
