import PDFDocument from "pdfkit";
import { CertificadoDataRepository } from "../../repository/services/detail.repository.js";

const formatDate = (date) => {
    if (!date) return null;

    const d = new Date(date);
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();

    return `${day}/${month}/${year}`;
};

const addOneYear = (date) => {
    if (!date) return null;

    const d = new Date(date);
    d.setFullYear(d.getFullYear() + 1);
    return formatDate(d);
};

const mapExtintorToCertificateRow = (item) => {
    const ext = item.extintor;
    const mantenimiento = item.mantenimientoDetalle;

    return {
        servicioExtintorId: item.id,
        extintorId: ext?.id || null,
        codigo: ext?.codeExtintor || "—",
        capacidad: ext?.capacity || "—",
        tipo: ext?.type || "—",
        marca: ext?.brand || "—",
        modelo: ext?.model || "—",
        numeroSerie: ext?.cylinderNumber || ext?.serialNumberNFC || "—",
        anioFabricacion: ext?.yearManufacture || "—",
        ph: ext?.dateHydrostatic ? formatDate(ext.dateHydrostatic) : "—",
        proximoMantenimiento: ext?.dateMaintenance
            ? addOneYear(ext.dateMaintenance)
            : "—",
        extintor: {
            id: ext?.id || null,
            codeExtintor: ext?.codeExtintor || null,
            serialNumberNFC: ext?.serialNumberNFC || null,
            type: ext?.type || null,
            capacity: ext?.capacity || null,
            agent: ext?.agent || null,
            cylinderNumber: ext?.cylinderNumber || null,
            location: ext?.location || null,
            brand: ext?.brand || null,
            model: ext?.model || null,
            rating: ext?.rating || null,
            yearManufacture: ext?.yearManufacture || null,
            dateHydrostatic: ext?.dateHydrostatic || null,
            dateMaintenance: ext?.dateMaintenance || null,
            dateLow: ext?.dateLow || null,
            pressure: ext?.pressure || null,
            status: ext?.status || null
        },
        mantenimientoDetalle: mantenimiento ? {
            id: mantenimiento.id,
            mantenimiento: mantenimiento.mantenimiento,
            recarga: mantenimiento.recarga,
            agenteCarga: mantenimiento.agenteCarga,
            pruebaHidrostatica: mantenimiento.pruebaHidrostatica,
            bajaExtintor: mantenimiento.bajaExtintor,
            motivoBaja: mantenimiento.motivoBaja,
            pintura: mantenimiento.pintura,
            recargaCartucho: mantenimiento.recargaCartucho,
            cambioPartes: mantenimiento.cambioPartes,
            detallesCambioPartes: mantenimiento.detallesCambioPartes
        } : null
    };
};

const filterByCertificateType = (items, tipo) => {
    if (tipo === "OPER") {
        return items.filter(item =>
            item.mantenimientoDetalle?.mantenimiento === true ||
            item.mantenimientoDetalle?.recarga === true ||
            item.mantenimientoDetalle?.pintura === true ||
            item.mantenimientoDetalle?.cambioPartes === true
        );
    }

    if (tipo === "HIDRO") {
        return items.filter(item =>
            item.mantenimientoDetalle?.pruebaHidrostatica === true
        );
    }

    if (tipo === "BAJA") {
        return items.filter(item =>
            item.mantenimientoDetalle?.bajaExtintor === true
        );
    }

    return [];
};

const buildResponseData = (service, tipo, extintoresFiltrados) => {
    return {
        certificadoTipo: tipo,
        cliente: service.sede?.client ? {
            id: service.sede.client.id,
            clientCode: service.sede.client.clientCode,
            razonSocial: service.sede.client.razonSocial,
            ruc: service.sede.client.ruc,
            phone: service.sede.client.phone,
            address: service.sede.client.address
        } : null,
        sede: service.sede ? {
            id: service.sede.id,
            name_sede: service.sede.name_sede,
            address: service.sede.address,
            manager_name: service.sede.manager_name,
            manager_phone: service.sede.manager_phone,
            manager_email: service.sede.manager_email,
            city: service.sede.city
        } : null,
        servicio: {
            id: service.id,
            type: service.type,
            status: service.status,
            statusValid: service.statusValid,
            dateStart: service.dateStart,
            dateEnd: service.dateEnd,
            createdAt: service.createdAt,
            updatedAt: service.updatedAt,
            tecnicoAsignado: service.user ? {
                id: service.user.id,
                name: service.user.name,
                email: service.user.email,
                userCode: service.user.userCode
            } : null
        },
        resumen: {
            totalExtintoresServicio: service.servicioExtintores.length,
            totalExtintoresCertificado: extintoresFiltrados.length
        },
        extintores: extintoresFiltrados
    };
};

const getValidatedServiceData = async (servicioId, tipo) => {
    const tiposValidos = ["OPER", "HIDRO", "BAJA"];

    if (!servicioId || isNaN(Number(servicioId))) {
        return {
            ok: false,
            status: 400,
            message: "El id del servicio es inválido"
        };
    }

    if (!tiposValidos.includes(tipo)) {
        return {
            ok: false,
            status: 400,
            message: "Tipo de certificado inválido. Use OPER, HIDRO o BAJA"
        };
    }

    const service = await CertificadoDataRepository.findServiceWithRelations(servicioId);

    if (!service) {
        return {
            ok: false,
            status: 404,
            message: "Servicio no encontrado"
        };
    }

    if (service.type !== "MANTENIMIENTO") {
        return {
            ok: false,
            status: 400,
            message: "Solo se puede generar certificado desde servicios de MANTENIMIENTO"
        };
    }

    if (service.status !== "FINALIZADO") {
        return {
            ok: false,
            status: 400,
            message: "Solo se puede generar certificado de servicios FINALIZADOS"
        };
    }

    const rows = service.servicioExtintores.map(mapExtintorToCertificateRow);
    const extintoresFiltrados = filterByCertificateType(rows, tipo);

    return {
        ok: true,
        status: 200,
        data: buildResponseData(service, tipo, extintoresFiltrados)
    };
};

const generatePdfBuffer = async (data) => {
    return new Promise((resolve, reject) => {
        const doc = new PDFDocument({
            size: "A4",
            margin: 40
        });

        const chunks = [];

        doc.on("data", chunk => chunks.push(chunk));
        doc.on("end", () => resolve(Buffer.concat(chunks)));
        doc.on("error", reject);

        doc.fontSize(16).text("CERTIFICADO", { align: "center" });
        doc.moveDown(1);

        doc.fontSize(11).text(`Tipo de certificado: ${data.certificadoTipo}`);
        doc.text(`Cliente: ${data.cliente?.razonSocial || "—"}`);
        doc.text(`RUC: ${data.cliente?.ruc || "—"}`);
        doc.text(`Sede: ${data.sede?.name_sede || "—"}`);
        doc.text(`Dirección: ${data.sede?.address || "—"}`);
        doc.text(`Ciudad: ${data.sede?.city || "—"}`);
        doc.text(`Servicio ID: ${data.servicio?.id || "—"}`);
        doc.text(`Estado servicio: ${data.servicio?.status || "—"}`);
        doc.text(`Fecha inicio: ${formatDate(data.servicio?.dateStart) || "—"}`);
        doc.text(`Fecha fin: ${formatDate(data.servicio?.dateEnd) || "—"}`);
        doc.moveDown(1);

        doc.fontSize(12).text("Detalle de extintores", { underline: true });
        doc.moveDown(0.5);

        const startX = 40;
        let y = doc.y;
        const rowHeight = 22;

        const columns = [
            { key: "codigo", label: "COD.", width: 55 },
            { key: "capacidad", label: "CAP.", width: 50 },
            { key: "tipo", label: "TIPO", width: 90 },
            { key: "marca", label: "MARCA", width: 65 },
            { key: "modelo", label: "MODELO", width: 65 },
            { key: "numeroSerie", label: "N° SERIE", width: 75 },
            { key: "anioFabricacion", label: "AÑO FAB.", width: 60 },
            { key: "ph", label: "P.H.", width: 55 },
            { key: "proximoMantenimiento", label: "PROX. MANTTO.", width: 85 }
        ];

        const drawRow = (row, isHeader = false) => {
            let x = startX;

            columns.forEach((col) => {
                doc.rect(x, y, col.width, rowHeight).stroke();
                doc.fontSize(isHeader ? 8 : 7)
                    .text(
                        isHeader ? col.label : String(row[col.key] ?? "—"),
                        x + 3,
                        y + 6,
                        {
                            width: col.width - 6,
                            align: "center"
                        }
                    );
                x += col.width;
            });

            y += rowHeight;

            if (y > 730) {
                doc.addPage();
                y = 40;
                drawRow({}, true);
            }
        };

        drawRow({}, true);

        if (!data.extintores.length) {
            doc.moveDown(2);
            doc.fontSize(10).text("No hay extintores para este tipo de certificado.");
        } else {
            data.extintores.forEach((item) => drawRow(item, false));
        }

        doc.end();
    });
};

export const CertificadoDataService = {
    async execute(servicioId, tipo) {
        return getValidatedServiceData(servicioId, tipo);
    },

    async generatePdf(servicioId, tipo) {
        const result = await getValidatedServiceData(servicioId, tipo);

        if (!result.ok) {
            return result;
        }

        const pdfBuffer = await generatePdfBuffer(result.data);

        return {
            ok: true,
            status: 200,
            fileName: `certificado_${tipo}_${servicioId}.pdf`,
            pdfBuffer
        };
    }
};