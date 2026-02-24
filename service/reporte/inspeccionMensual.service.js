import { prisma } from '../../database/client.mjs'

export const ReporteInspeccionMensualService = {

    async generar(servicioId) {

        const servicio = await prisma.servicio.findUnique({
            where: { id: servicioId },
            include: {
                sede: { include: { client: true } },
                servicioExtintores: {
                    include: {
                        extintor: true,
                        inspeccionDetalle: true
                    }
                }
            }
        })

        if (!servicio) return null

        return {
            empresa: servicio.sede.client.razonSocial,
            ruc: servicio.sede.client.ruc,
            instalacion: servicio.sede.name_sede,
            direccion: servicio.sede.address,
            ciudad: servicio.sede.city,
            mes: servicio.dateStart,

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
                    ph: e.dateHydrostatic,
                    ubicacionEquipo: e.location,
                    fechaVencMantto: e.dateMaintenance,
                    fechaPruebaHidro: e.dateHydrostatic,

                    // Checklist
                    ubicadoNumeracion: i?.ubicacion,
                    accesoLibre: i?.accesibilidad,
                    alturaAdecuada: i?.instalacion,
                    pictogramaUso: i?.instrucciones,
                    pictogramaClase: i?.clasificacion,
                    manometro: i?.presion,
                    precinto: i?.seguridad,
                    cilindroEstado: i?.estado,
                    indicaAgente: i?.carga,
                    colgador: i?.soporte,
                    manija: i?.activacion,
                    manguera: i?.manguera,
                    tobera: i?.boquilla,
                    sujetador: i?.abrazadera,

                    observaciones: i?.observaciones
                }
            })
        }
    }
}
