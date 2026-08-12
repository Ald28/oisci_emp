import { prisma } from '../../database/client.mjs'

export const ReporteInspeccionRepository = {

    async obtenerServicio(servicioId) {
        return prisma.servicio.findUnique({
            where: { id: servicioId },
            include: {
                sede: {
                    include: {
                        client: true
                    }
                },
                user: true,
                certificados: {
                    orderBy: {
                        createdAt: 'desc',
                    },
                    take: 1,
                    select: {
                        tipo: true,
                        numeroCertificado: true,
                        fechaEmision: true,
                    },
                },
            }
        })
    },

    async obtenerInspecciones(servicioId) {
        return prisma.servicioExtintor.findMany({
            where: {
                servicioId,
            },
            include: {
                extintor: true,
                inspeccionDetalle: true,
                mantenimientoDetalle: true,
            }
        })
    },

    async listarServiciosAptos() {
        return prisma.servicio.findMany({
            where: {
                type: 'MANTENIMIENTO',
                status: 'FINALIZADO',
            },
            select: {
                id: true,
            },
            orderBy: {
                id: 'desc',
            },
        })
    }

}