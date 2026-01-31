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
                }
            }
        })
    },

    async obtenerInspecciones(servicioId) {
        return prisma.servicioExtintor.findMany({
            where: {
                servicioId,
                inspeccionDetalle: {
                    isNot: null
                }
            },
            include: {
                extintor: true,
                inspeccionDetalle: true
            }
        })
    }

}