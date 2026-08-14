import { prisma } from '../../database/client.mjs'

export const ReporteMantenimientoAnualService = {
    async listar(servicioId = null) {
        const servicios = await prisma.servicio.findMany({
            where: {
                type: 'MANTENIMIENTO',
                ...(servicioId ? { id: Number(servicioId) } : {}),
            },
            include: {
                sede: { include: { client: true } },
                user: true,
                servicioExtintores: {
                    where: { extintor: { historic: 0 } },
                    include: {
                        extintor: true,
                        mantenimientoDetalle: true,
                        inspeccionDetalle: true,
                    },
                    orderBy: { id: 'asc' },
                },
            },
            orderBy: [{ dateStart: 'desc' }, { id: 'desc' }],
        })

        const extintorIds = [...new Set(servicios.flatMap((servicio) =>
            servicio.servicioExtintores.map((item) => item.extintorId)))]

        // Una inspección pertenece a otro ServicioExtintor. Por eso no se debe
        // tomar el inspeccionDetalle del mantenimiento actual, sino la última
        // inspección registrada para el mismo extintor hasta la fecha de hoy.
        const inspecciones = extintorIds.length
            ? await prisma.servicioExtintor.findMany({
                where: {
                    extintorId: { in: extintorIds },
                    inspeccionDetalle: { isNot: null },
                    servicio: {
                        type: 'INSPECCION',
                        dateStart: { lte: new Date() },
                    },
                },
                include: {
                    inspeccionDetalle: true,
                    servicio: { select: { id: true, dateStart: true, status: true } },
                },
                orderBy: [
                    { servicio: { dateStart: 'desc' } },
                    { id: 'desc' },
                ],
            })
            : []

        const ultimaInspeccionPorExtintor = new Map()
        inspecciones.forEach((inspeccion) => {
            if (!ultimaInspeccionPorExtintor.has(inspeccion.extintorId)) {
                ultimaInspeccionPorExtintor.set(inspeccion.extintorId, inspeccion)
            }
        })

        // Garantiza servicio -> sede -> extintorId asociado al mismo servicio y sede.
        return servicios.map((servicio) => ({
            ...servicio,
            servicioExtintores: servicio.servicioExtintores
                .filter((item) => item.extintor.sedeId === servicio.sedeId)
                .map((item) => {
                    const ultimaInspeccion = ultimaInspeccionPorExtintor.get(item.extintorId) || null
                    return {
                        ...item,
                        // Conserva este campo para los consumidores actuales del reporte.
                        inspeccionDetalle: ultimaInspeccion?.inspeccionDetalle || null,
                        ultimaInspeccion,
                    }
                }),
        }))
    },
}
