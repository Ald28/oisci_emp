import { RegisterRepository } from '../../repository/services/register.repository.js'

export const RegisterService = {

    async registerServicio(data, usuarioId) {

        if (!data.extintores || data.extintores.length === 0) {
            throw new Error('Debe registrar al menos un extintor')
        }

        return RegisterRepository.createServicioWithExtintores({
            type: data.type,
            dateStart: new Date(data.dateStart),
            sedeId: data.sedeId,
            userId: data.userId,
            usuarioCreadorId: usuarioId,
            extintores: data.extintores
        })
    }

}