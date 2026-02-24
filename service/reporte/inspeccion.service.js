import { ReporteInspeccionRepository } from '../../repository/reporte/inspeccion.repository.js'

export const ReporteInspeccionService = {

    async generar(servicioId) {

        const servicio = await ReporteInspeccionRepository.obtenerServicio(servicioId)
        if (!servicio) return null

        const inspecciones = await ReporteInspeccionRepository.obtenerInspecciones(servicioId)

        // Ordenar por extintor y fecha
        inspecciones.sort((a, b) => {
            if (a.extintorId !== b.extintorId) {
                return a.extintorId - b.extintorId
            }
            return new Date(a.createdAt) - new Date(b.createdAt)
        })

        return {
            servicio: {
                id: servicio.id,
                tipo: servicio.type,
                fechaInicio: servicio.dateStart,
                fechaFin: servicio.dateEnd
            },

            cliente: {
                razonSocial: servicio.sede.client.razonSocial,
                ruc: servicio.sede.client.ruc
            },

            sede: {
                nombre: servicio.sede.name_sede,
                direccion: servicio.sede.address,
                ciudad: servicio.sede.city
            },

            equipos: inspecciones.map(i => ({
                extintorId: i.extintor.id,
                codigo: i.extintor.codeExtintor,
                tipo: i.extintor.type,
                ubicacion: i.extintor.location,

                estadoFinal: i.estadoFinal,

                fotos: i.inspeccionDetalle
                    ? {
                        foto1Url: i.inspeccionDetalle.foto1Url,
                        foto2Url: i.inspeccionDetalle.foto2Url,
                        foto3Url: i.inspeccionDetalle.foto3Url
                    }
                    : null,

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
                        abrazadera: i.inspeccionDetalle.abrazadera
                    }
                    : null,

                observaciones: i.inspeccionDetalle?.observaciones ?? null,
                fechaHora: i.inspeccionDetalle?.createdAt ?? null
            }))
        }
    }

}