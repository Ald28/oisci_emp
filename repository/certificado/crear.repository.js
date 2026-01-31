import { prisma } from '../../database/client.mjs'

export const CreateCertificado = {
    async create(data) {
        return prisma.certificado.create({
            data: {
                tipo: data.tipo,
                numeroCertificado: data.numeroCertificado,
                frecuencia: data.frecuencia,

                client: {
                    connect: { id: data.clientId }
                },

                sede: {
                    connect: { id: data.sedeId }
                },

                servicio: {
                    connect: { id: data.servicioId }
                },

                usuarioCreador: {
                    connect: { id: data.usuarioId }
                },

                aprobador: {
                    connect: { id: data.usuarioId }
                },

                usuarioActualizador: {
                    connect: { id: data.usuarioId }
                },

                certificadoDetalles: {
                    create: data.extintores.map(e => ({
                        estado: e.estado,
                        checklist: e.checklist,

                        extintor: {
                            connect: { id: e.extintorId }
                        }
                    }))
                }
            },
            include: {
                client: true,
                sede: true,
                certificadoDetalles: {
                    include: { extintor: true }
                }
            }
        })
    },

    async guardarPdf({ id, archivoPdfUrl, usuarioId }) {
        return prisma.certificado.update({
            where: { id },
            data: {
                archivoPdfUrl,
                emitido: 'SI',
                fechaEmision: new Date(),

                usuarioActualizador: {
                    connect: { id: usuarioId }
                }
            }
        })
    },

    async obtenerFotosPorServicio(servicioId) {
        return prisma.servicioExtintor.findMany({
            where: { servicioId },
            include: {
                extintor: true,
                inspeccionDetalle: true
            },
            orderBy: [
                { extintorId: 'asc' }
            ]
        })
    }
}