import { prisma } from "../../database/client.mjs";

export const CertificadoDataRepository = {
    async findServiceWithRelations(servicioId) {
        return prisma.servicio.findUnique({
            where: {
                id: Number(servicioId)
            },
            include: {
                sede: {
                    include: {
                        client: true
                    }
                },
                usuarioCreador: true,
                usuarioActualizador: true,
                user: true,
                servicioExtintores: {
                    include: {
                        extintor: true,
                        mantenimientoDetalle: true,
                        inspeccionDetalle: true,
                        usuarioCreador: true,
                        usuarioActualizador: true
                    }
                },
                certificados: true
            }
        });
    }
};