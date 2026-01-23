import { ListRepository } from '../../repository/services/list.repository.js'

export const ListService = {

    async listServicioExtintores(servicioId) {
        const servicio = await ListRepository.findById(servicioId)

        if (!servicio) {
            throw new Error('Servicio no encontrado')
        }

        return ListRepository.findServicioExtintores(servicioId)
    },

    async getInProgressByUser(usuarioId) {
        return ListRepository.findInProgressByUser(usuarioId)
    },

    async getById(servicioId) {
        return ListRepository.findById(servicioId)
    },

    async getBySedeId(sedeId) {
        if (isNaN(Number(sedeId))) {
            throw new Error('sedeId inválido')
        }

        return ListRepository.findBySedeId(sedeId)
    },

    /**
     * Obtener todos los servicios con detalles completos
     * Para sincronización inicial
     */
    async getAllWithDetails() {
        return ListRepository.findAllWithDetails()
    },

    /**
     * Obtener servicios modificados después de un timestamp
     * Para sincronización incremental
     */
    async getUpdatedSince(since) {
        return ListRepository.findUpdatedSince(since)
    }

}

export async function getServiciosStatsBySedeYearService(sedeId, year) {
    const servicios =
        await ListRepository.getBySedeAndYear(sedeId, year)

    let mantenimiento = 0
    let recarga = 0
    let pruebaHidrostatica = 0
    let baja = 0

    for (const servicio of servicios) {

        if (servicio.type === 'MANTENIMIENTO') {
            mantenimiento++
        }

        for (const se of servicio.servicioExtintores) {
            const md = se.mantenimientoDetalle

            if (!md) continue

            if (md.recarga === true) {
                recarga++
            }

            if (md.pruebaHidrostatica === true) {
                pruebaHidrostatica++
            }

            if (
                md.bajaExtintor === true ||
                se.estadoFinal === 'INOPERATIVO'
            ) {
                baja++
            }
        }
    }

    return {
        sedeId: Number(sedeId),
        year: Number(year),
        byType: {
            MANTENIMIENTO: mantenimiento,
            RECARGA: recarga,
            'PRUEBA HIDROSTÁTICA': pruebaHidrostatica,
            BAJA: baja
        }
    }
}