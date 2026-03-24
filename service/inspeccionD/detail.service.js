import PDFDocument from "pdfkit";
import { CertificadoDataRepository } from "../../repository/inpeccionD/detail.repository.js";
import { obtenerKeyDesdeS3Url } from "./storage/keyS3.js";

const formatDate = (date) => {
    if (!date) return null;

    const d = new Date(date);
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();

    return `${day}/${month}/${year}`;
};

const buildPreviewUrl = (url) => {
    if (!url) return null;

    const key = obtenerKeyDesdeS3Url(url);

    return `${process.env.API_URL}/certificado/preview?key=${encodeURIComponent(key)}`;
};

const mapInspectionPhotos = (inspeccion) => {
    if (!inspeccion) return null;

    return {
        ...inspeccion,
        foto1Url: buildPreviewUrl(inspeccion.foto1Url),
        foto2Url: buildPreviewUrl(inspeccion.foto2Url),
        foto3Url: buildPreviewUrl(inspeccion.foto3Url),
        foto4Url: buildPreviewUrl(inspeccion.foto4Url)
    };
};

const mapExtintorToInspectionRow = (item) => {
    const ext = item.extintor;
    const inspeccion = item.inspeccionDetalle;

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
        ubicacionExtintor: ext?.location || "—",
        estadoExtintor: ext?.status || "—",
        estadoInicial: item.estadoInicial || "—",
        estadoFinal: item.estadoFinal || "—",
        completado: item.completado,
        observacionesServicio: item.observaciones || "—",
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
            status: ext?.status || null,
            rechargeDate: ext?.rechargeDate || null,
            photo: buildPreviewUrl(ext?.photo)
        },
        inspeccionDetalle: mapInspectionPhotos(inspeccion)
            ? {
                id: inspeccion.id,
                foto1Url: buildPreviewUrl(inspeccion.foto1Url),
                foto2Url: buildPreviewUrl(inspeccion.foto2Url),
                foto3Url: buildPreviewUrl(inspeccion.foto3Url),
                foto4Url: buildPreviewUrl(inspeccion.foto4Url),
                ubicacion: inspeccion.ubicacion,
                accesibilidad: inspeccion.accesibilidad,
                instalacion: inspeccion.instalacion,
                instrucciones: inspeccion.instrucciones,
                clasificacion: inspeccion.clasificacion,
                recarga: inspeccion.recarga,
                certificacion: inspeccion.certificacion,
                presion: inspeccion.presion,
                seguridad: inspeccion.seguridad,
                estado: inspeccion.estado,
                carga: inspeccion.carga,
                soporte: inspeccion.soporte,
                activacion: inspeccion.activacion,
                manguera: inspeccion.manguera,
                boquilla: inspeccion.boquilla,
                abrazadera: inspeccion.abrazadera,
                observaciones: inspeccion.observaciones,
                createdAt: inspeccion.createdAt,
                updatedAt: inspeccion.updatedAt
            }
            : null
    };
};

const getValidatedServiceData = async (servicioId) => {
    if (!servicioId || isNaN(Number(servicioId))) {
        return {
            ok: false,
            status: 400,
            message: "El id del servicio es inválido"
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

    if (service.type !== "INSPECCION") {
        return {
            ok: false,
            status: 400,
            message: "Solo se puede generar reporte desde servicios de INSPECCION"
        };
    }

    if (service.status !== "FINALIZADO") {
        return {
            ok: false,
            status: 400,
            message: "Solo se puede generar reporte de servicios FINALIZADOS"
        };
    }

    const extintores = service.servicioExtintores.map(mapExtintorToInspectionRow);

    return {
        ok: true,
        status: 200,
        data: {
            reporteTipo: "INSPECCION",
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
                totalExtintoresReporte: extintores.length
            },
            extintores
        }
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

        doc.fontSize(16).text("REPORTE DE INSPECCIÓN", { align: "center" });
        doc.moveDown(1);

        doc.fontSize(11).text(`Cliente: ${data.cliente?.razonSocial || "—"}`);
        doc.text(`RUC: ${data.cliente?.ruc || "—"}`);
        doc.text(`Sede: ${data.sede?.name_sede || "—"}`);
        doc.text(`Dirección: ${data.sede?.address || "—"}`);
        doc.text(`Ciudad: ${data.sede?.city || "—"}`);
        doc.text(`Servicio ID: ${data.servicio?.id || "—"}`);
        doc.text(`Tipo: ${data.servicio?.type || "—"}`);
        doc.text(`Estado servicio: ${data.servicio?.status || "—"}`);
        doc.text(`Fecha inicio: ${formatDate(data.servicio?.dateStart) || "—"}`);
        doc.text(`Fecha fin: ${formatDate(data.servicio?.dateEnd) || "—"}`);
        doc.moveDown(1);

        doc.fontSize(12).text("Detalle de extintores inspeccionados", { underline: true });
        doc.moveDown(0.5);

        data.extintores.forEach((item, index) => {
            if (doc.y > 700) {
                doc.addPage();
            }

            doc.fontSize(10).text(`${index + 1}. Código: ${item.codigo}`);
            doc.fontSize(9).text(`Tipo: ${item.tipo} | Capacidad: ${item.capacidad} | Marca: ${item.marca} | Modelo: ${item.modelo}`);
            doc.text(`Serie: ${item.numeroSerie} | Año: ${item.anioFabricacion} | Ubicación: ${item.ubicacionExtintor}`);
            doc.text(`Estado inicial: ${item.estadoInicial} | Estado final: ${item.estadoFinal} | Completado: ${item.completado ? "Sí" : "No"}`);
            doc.text(`Observación servicio: ${item.observacionesServicio}`);

            const detalle = item.inspeccionDetalle;

            if (detalle) {
                doc.text(`Accesibilidad: ${detalle.accesibilidad || "—"} | Instalación: ${detalle.instalacion || "—"} | Instrucciones: ${detalle.instrucciones || "—"}`);
                doc.text(`Clasificación: ${detalle.clasificacion || "—"} | Recarga: ${detalle.recarga || "—"} | Certificación: ${detalle.certificacion || "—"}`);
                doc.text(`Presión: ${detalle.presion || "—"} | Seguridad: ${detalle.seguridad || "—"} | Estado: ${detalle.estado || "—"}`);
                doc.text(`Carga: ${detalle.carga || "—"} | Soporte: ${detalle.soporte || "—"} | Activación: ${detalle.activacion || "—"}`);
                doc.text(`Manguera: ${detalle.manguera || "—"} | Boquilla: ${detalle.boquilla || "—"} | Abrazadera: ${detalle.abrazadera || "—"}`);
                doc.text(`Observaciones inspección: ${detalle.observaciones || "—"}`);
            }

            doc.moveDown(0.8);
        });

        if (!data.extintores.length) {
            doc.fontSize(10).text("No hay extintores relacionados para este reporte.");
        }

        doc.end();
    });
};

export const CertificadoDataService = {
    async execute(servicioId) {
        return getValidatedServiceData(servicioId);
    },

    async generatePdf(servicioId) {
        const result = await getValidatedServiceData(servicioId);

        if (!result.ok) {
            return result;
        }

        const pdfBuffer = await generatePdfBuffer(result.data);

        return {
            ok: true,
            status: 200,
            fileName: `reporte_inspeccion_${servicioId}.pdf`,
            pdfBuffer
        };
    }
};