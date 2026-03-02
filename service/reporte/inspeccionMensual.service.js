import { prisma } from '../../database/client.mjs'
import { toPeruDateTime } from '../../utils/datetime.js'

export const ReporteInspeccionMensualService = {

    async generar(servicioId) {

        const servicio = await prisma.servicio.findUnique({
            where: { id: servicioId },
            include: {
                sede: { include: { client: true } },
                servicioExtintores: {
                    include: {
                        extintor: true,
                        inspeccionDetalle: true,
                    },
                },
            },
        })

        if (!servicio) return null

        return {
            empresa: servicio.sede.client.razonSocial,
            ruc: servicio.sede.client.ruc,
            instalacion: servicio.sede.name_sede,
            direccion: servicio.sede.address,
            ciudad: servicio.sede.city,

            // ✅ ISO en hora Perú para Flutter
            mes: toPeruDateTime(servicio.dateStart),

            equipos: servicio.servicioExtintores.map((se, index) => {
                const e = se.extintor
                const i = se.inspeccionDetalle

                return {
                    numero: index + 1,

                    codigo: e.codeExtintor,
                    capacidad: e.capacity,
                    tipo: e.type,
                    claseRating: e.rating,
                    presionEquipo: e.pressure,
                    marca: e.brand,
                    modelo: e.model,
                    numeroSerie: e.serialNumberNFC,
                    numeroCilindro: e.cylinderNumber,
                    anioFabricacion: e.yearManufacture,

                    // ✅ Fechas ISO -05:00 (parseable)
                    ph: toPeruDateTime(e.dateHydrostatic),
                    ubicacionEquipo: e.location,
                    fechaVencMantto: toPeruDateTime(e.dateMaintenance),
                    fechaPruebaHidro: toPeruDateTime(e.dateHydrostatic),

                    // Checklist
                    ubicadoNumeracion: i?.ubicacion ?? null,
                    accesoLibre: i?.accesibilidad ?? null,
                    alturaAdecuada: i?.instalacion ?? null,
                    pictogramaUso: i?.instrucciones ?? null,
                    pictogramaClase: i?.clasificacion ?? null,
                    manometro: i?.presion ?? null,
                    precinto: i?.seguridad ?? null,
                    cilindroEstado: i?.estado ?? null,
                    indicaAgente: i?.carga ?? null,
                    colgador: i?.soporte ?? null,
                    manija: i?.activacion ?? null,
                    manguera: i?.manguera ?? null,
                    tobera: i?.boquilla ?? null,
                    sujetador: i?.abrazadera ?? null,

                    observaciones: i?.observaciones ?? null,
                }
            }),
        }
    },
}
