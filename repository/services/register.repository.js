import { prisma } from '../../database/client.mjs'

export const RegisterRepository = {

    async createServicioWithExtintores({
        type,
        dateStart,
        sedeId,
        userId,
        usuarioCreadorId,
        extintores
    }) {
        return prisma.$transaction(async (tx) => {

            const servicio = await tx.servicio.create({
                data: {
                    type,
                    dateStart,
                    status: 'EN_PROCESO',
                    statusValid: 'APROBADO',
                    sedeId,
                    userId,
                    usuarioCreadorId
                }
            })

            await tx.servicioExtintor.createMany({
                data: extintores.map(e => ({
                    servicioId: servicio.id,
                    extintorId: e.extintorId,
                    estadoInicial: e.estadoInicial,
                    observaciones: e.observaciones,
                    usuarioCreadorId
                }))
            })

            return servicio
        })
    }

}