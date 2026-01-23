import { ListService, getServiciosStatsBySedeYearService } from '../../service/services/list.service.js'

export const ListController = {
    async listServicioExtintores(req, res) {
        try {
            const { servicioId } = req.params

            const extintores =
                await ListService.listServicioExtintores(servicioId)

            res.status(200).json({
                data: extintores
            })
        } catch (error) {
            res.status(400).json({ message: error.message })
        }
    },

    async getInProgress(req, res) {
        try {
            const usuarioId = req.user.sub

            const servicios =
                await ListService.getInProgressByUser(usuarioId)

            res.status(200).json({
                data: servicios
            })

        } catch (error) {
            res.status(400).json({ message: error.message })
        }

    },

    async getById(req, res) {
        try {
            const { servicioId } = req.params

            if (!servicioId) {
                return res.status(400).json({ message: 'servicioId es requerido' })
            }

            // Validar que servicioId sea un número válido
            const servicioIdNum = Number(servicioId)
            if (isNaN(servicioIdNum)) {
                return res.status(400).json({ message: 'servicioId debe ser un número válido' })
            }

            const servicio = await ListService.getById(servicioIdNum)

            if (!servicio) {
                return res.status(404).json({ message: 'Servicio no encontrado' })
            }

            res.status(200).json({
                data: servicio
            })

        } catch (error) {
            console.error(error)
            res.status(500).json({ message: error.message })
        }
    },

    async getBySede(req, res) {
        try {
            const { sedeId } = req.params

            if (!sedeId) {
                return res.status(400).json({
                    message: 'sedeId es requerido'
                })
            }

            const sedeIdNum = Number(sedeId)
            if (isNaN(sedeIdNum)) {
                return res.status(400).json({
                    message: 'sedeId debe ser un número válido'
                })
            }

            const servicios = await ListService.getBySedeId(sedeIdNum)

            return res.status(200).json({
                data: servicios
            })

        } catch (error) {
            return res.status(500).json({
                message: error.message
            })
        }
    },

    /**
     * Obtener todos los servicios con detalles completos
     * Para sincronización inicial del frontend
     */
    async getAllWithDetails(req, res) {
        try {
            const servicios = await ListService.getAllWithDetails()

            return res.status(200).json({
                data: servicios
            })
        } catch (error) {
            return res.status(500).json({
                message: error.message
            })
        }
    },

    /**
     * Obtener servicios modificados después de un timestamp
     * Para sincronización incremental
     * GET /services/sync/incremental?since=2026-01-22T10:00:00Z
     */
    async getUpdatedSince(req, res) {
        try {
            const since = req.query.since
            
            if (!since || typeof since !== 'string') {
                return res.status(400).json({
                    message: 'El parámetro "since" es requerido (ISO 8601 timestamp)'
                })
            }

            const servicios = await ListService.getUpdatedSince(since)

            return res.status(200).json({
                data: servicios
            })
        } catch (error) {
            return res.status(500).json({
                message: error.message
            })
        }
    }

}

export async function getServiciosStatsBySedeYearController(req, res) {
    try {
        const sedeId = Number(req.params.sedeId)
        const year = Number(req.query.year)

        if (isNaN(sedeId) || isNaN(year)) {
            return res.status(400).json({
                ok: false,
                message: 'sedeId o year inválido'
            })
        }

        const stats =
            await getServiciosStatsBySedeYearService(sedeId, year)

        return res.status(200).json({
            ok: true,
            data: stats
        })

    } catch (error) {
        return res.status(500).json({
            ok: false,
            message: 'Error al obtener estadísticas de servicios',
            error: error.message
        })
    }
}