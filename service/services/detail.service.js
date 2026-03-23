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

export const CertificadoDataService = {
    async execute(servicioId, tipo) {
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
            data: {
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
            }
        };
    }
};