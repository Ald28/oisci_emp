import { ReporteInspeccionRepository } from '../../repository/reporte/inspeccion.repository.js'
import { toPeruDateTime } from '../../utils/datetime.js'

const filtrarEquiposPorTipo = (equipos, tipo) => {
    if (!tipo) return equipos

    if (tipo === 'OPER') {
        return equipos.filter((equipo) => {
            const m = equipo.mantenimientoDetalle || {}
            return Boolean(
                m.mantenimiento
                || m.recarga
                || m.pintura
                || m.cambioPartes
                || equipo.estadoFinal === 'OPERATIVO'
            )
        })
    }

    if (tipo === 'HIDRO') {
        return equipos.filter((equipo) => Boolean(equipo.mantenimientoDetalle?.pruebaHidrostatica))
    }

    if (tipo === 'BAJA') {
        return equipos.filter((equipo) => Boolean(equipo.mantenimientoDetalle?.bajaExtintor))
    }

    return equipos
}

export const ReporteInspeccionService = {
    async generar(servicioId) {
        const servicio = await ReporteInspeccionRepository.obtenerServicio(servicioId)
        if (!servicio) return null

        const inspecciones = await ReporteInspeccionRepository.obtenerInspecciones(servicioId)

        // Ordenar por extintor y fecha de inspección
        inspecciones.sort((a, b) => {
            if (a.extintorId !== b.extintorId) {
                return a.extintorId - b.extintorId
            }
            const fechaA = a.inspeccionDetalle?.createdAt ?? a.mantenimientoDetalle?.createdAt ?? a.createdAt
            const fechaB = b.inspeccionDetalle?.createdAt ?? b.mantenimientoDetalle?.createdAt ?? b.createdAt
            return new Date(fechaA) - new Date(fechaB)
        })

        const certificado = servicio.certificados?.[0] ?? null

        return {
            servicio: {
                id: servicio.id,
                tipo: servicio.type,
                certificadoTipo: certificado?.tipo ?? null,
                numeroCertificado: certificado?.numeroCertificado ?? null,
                fechaEmision: toPeruDateTime(certificado?.fechaEmision),

                // ISO en hora Perú (-05:00) y parseable por Flutter
                fechaInicio: toPeruDateTime(servicio.dateStart),
                fechaFin: toPeruDateTime(servicio.dateEnd),
            },

            cliente: {
                razonSocial: servicio.sede.client.razonSocial,
                ruc: servicio.sede.client.ruc,
            },

            sede: {
                nombre: servicio.sede.name_sede,
                direccion: servicio.sede.address,
                ciudad: servicio.sede.city,
            },
            equipos: inspecciones.map((i) => ({
                extintorId: i.extintor.id,
                codigo: i.extintor.codeExtintor,
                tipo: i.extintor.type,
                ubicacion: i.extintor.location,
                capacidad: i.extintor.capacity,
                agente: i.extintor.agent,
                nSerie: i.extintor.serialNumberNFC ?? i.extintor.cylinderNumber ?? null,
                marca: i.extintor.brand,
                modelo: i.extintor.model,
                anioFabricacion: i.extintor.yearManufacture,
                presionTrabajo: i.extintor.pressure ?? null,
                presionPrueba: i.extintor.rating ?? null,
                fechaHidrostatica: toPeruDateTime(i.extintor.dateHydrostatic),
                fechaMantenimiento: toPeruDateTime(i.extintor.dateMaintenance),
                fechaBaja: toPeruDateTime(i.extintor.dateLow),

                estadoFinal: i.estadoFinal,
                recomendaciones:
                    i.inspeccionDetalle?.observaciones
                    ?? i.observaciones
                    ?? i.mantenimientoDetalle?.detallesCambioPartes
                    ?? 'Ninguna',

                mantenimientoDetalle: i.mantenimientoDetalle
                    ? {
                        mantenimiento: i.mantenimientoDetalle.mantenimiento,
                        recarga: i.mantenimientoDetalle.recarga,
                        pruebaHidrostatica: i.mantenimientoDetalle.pruebaHidrostatica,
                        bajaExtintor: i.mantenimientoDetalle.bajaExtintor,
                        pintura: i.mantenimientoDetalle.pintura,
                        cambioPartes: i.mantenimientoDetalle.cambioPartes,
                        motivoBaja: i.mantenimientoDetalle.motivoBaja,
                    }
                    : null,

                fotos: i.inspeccionDetalle
                    ? {
                        foto1Url: i.inspeccionDetalle.foto1Url,
                        foto2Url: i.inspeccionDetalle.foto2Url,
                        foto3Url: i.inspeccionDetalle.foto3Url,
                    }
                    : null,
                fotosArray: i.inspeccionDetalle
                    ? [
                        i.inspeccionDetalle.foto1Url,
                        i.inspeccionDetalle.foto2Url,
                        i.inspeccionDetalle.foto3Url,
                    ].filter(Boolean)
                    : [],

                checklist: i.inspeccionDetalle
                    ? {
                        ubicacion: i.inspeccionDetalle.ubicacion,
                        accesibilidad: i.inspeccionDetalle.accesibilidad,
                        instalacion: i.inspeccionDetalle.instalacion,
                        instrucciones: i.inspeccionDetalle.instrucciones,
                        clasificacion: i.inspeccionDetalle.clasificacion,
                        presion: i.inspeccionDetalle.presion,
                        seguridad: i.inspeccionDetalle.seguridad,
                        estado: i.inspeccionDetalle.estado,
                        carga: i.inspeccionDetalle.carga,
                        soporte: i.inspeccionDetalle.soporte,
                        activacion: i.inspeccionDetalle.activacion,
                        manguera: i.inspeccionDetalle.manguera,
                        boquilla: i.inspeccionDetalle.boquilla,
                        abrazadera: i.inspeccionDetalle.abrazadera,
                    }
                    : null,

                observaciones: i.inspeccionDetalle?.observaciones ?? null,

                // ISO en hora Perú (-05:00) y parseable por Flutter
                fechaHora: toPeruDateTime(i.inspeccionDetalle?.createdAt),
            })),
        }
    },

    filtrarPorTipo(equipos, tipo) {
        return filtrarEquiposPorTipo(equipos, tipo)
    },

    async listar({ tipo } = {}) {
        const servicios = await ReporteInspeccionRepository.listarServiciosAptos()
        const resultados = []

        for (const servicio of servicios) {
            const reporte = await this.generar(servicio.id)
            if (!reporte) continue

            const equipos = Array.isArray(reporte.equipos) ? reporte.equipos : []
            const equiposFiltrados = filtrarEquiposPorTipo(equipos, tipo)

            if (tipo && equiposFiltrados.length === 0) {
                continue
            }

            resultados.push({
                servicioId: reporte.servicio.id,
                numeroCertificado: reporte.servicio.numeroCertificado,
                fechaInicio: reporte.servicio.fechaInicio,
                fechaEmision: reporte.servicio.fechaEmision,
                certificadoTipo: reporte.servicio.certificadoTipo,
                cliente: reporte.cliente,
                totalEquipos: equipos.length,
                totalEquiposFiltrados: equiposFiltrados.length,
            })
        }

        return resultados
    },
}
