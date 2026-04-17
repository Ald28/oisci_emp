import { CreateCertificado } from '../../repository/certificado/crear.repository.js'
import { generarNumeroCertificado } from '../../utils/generarNumeroCertificado.js'
import { presignPreview } from '../../utils/presignPreview.js'
import { obtenerKeyDesdeS3Url } from '../inspeccionD/storage/keyS3.js'

const TIPOS_CERTIFICADO_VALIDOS = [
    'OPER',
    'BAJA',
    'HIDRO',
    'HIDROSTATICA',
    'REPORTE_TECNICO'
]

const normalizarTipoCertificado = (tipo) => {
    if (tipo === 'HIDROSTATICA') return 'HIDRO'
    return tipo
}

export const CertificadoService = {

    async createCertificado({ body, usuarioId }) {
        const { tipo, clientId, sedeId, servicioId, frecuencia, extintores } = body

        if (!tipo) {
            throw new Error('tipo es requerido')
        }

        if (!TIPOS_CERTIFICADO_VALIDOS.includes(tipo)) {
            throw new Error(
                `tipo no válido. Debe ser uno de: ${TIPOS_CERTIFICADO_VALIDOS.join(', ')}`
            )
        }

        if (!clientId || isNaN(clientId)) {
            throw new Error('clientId es requerido y debe ser numérico')
        }

        if (!sedeId || isNaN(sedeId)) {
            throw new Error('sedeId es requerido y debe ser numérico')
        }

        if (!servicioId || isNaN(servicioId)) {
            throw new Error('servicioId es requerido y debe ser numérico')
        }

        if (!frecuencia) {
            throw new Error('frecuencia es requerida')
        }

        if (!Array.isArray(extintores) || extintores.length === 0) {
            throw new Error('extintores es requerido y debe ser un arreglo con al menos un elemento')
        }

        const tipoNormalizado = normalizarTipoCertificado(tipo)

        const numeroCertificado = await generarNumeroCertificado(tipoNormalizado)

        return CreateCertificado.create({
            ...body,
            tipo: tipoNormalizado,
            numeroCertificado,
            usuarioId
        })
    },

    async subirPdf({ certificadoId, archivoPdfUrl, usuarioId }) {
        return CreateCertificado.guardarPdf({
            id: certificadoId,
            archivoPdfUrl,
            usuarioId
        })
    },

    async generarPreviewUrl(urlOrKey) {
        const key = obtenerKeyDesdeS3Url(urlOrKey)
        return await presignPreview(key, 'imagen.jpg')
    },

    async generarReporte(servicioId) {
        const registros = await CreateCertificado.obtenerFotosPorServicio(servicioId)

        registros.sort((a, b) => {
            if (a.extintorId !== b.extintorId) {
                return a.extintorId - b.extintorId
            }

            const fechaA = a.inspeccionDetalle?.createdAt
                ? new Date(a.inspeccionDetalle.createdAt).getTime()
                : 0

            const fechaB = b.inspeccionDetalle?.createdAt
                ? new Date(b.inspeccionDetalle.createdAt).getTime()
                : 0

            return fechaA - fechaB
        })

        return registros.map((r) => {
            const fotosOriginales = [
                r.inspeccionDetalle?.foto1Url,
                r.inspeccionDetalle?.foto2Url,
                r.inspeccionDetalle?.foto3Url
            ].filter(Boolean)

            const fotosBackend = fotosOriginales.map((urlOrKey) => {
                const key = obtenerKeyDesdeS3Url(urlOrKey)
                const url = `${process.env.API_URL}/certificado/preview?key=${encodeURIComponent(key)}`
                console.log('URL final enviada al frontend:', url)
                return url
            })

            return {
                extintorId: r.extintorId,
                codeExtintor: r.extintor?.codeExtintor ?? null,
                serialNumberNFC: r.extintor?.serialNumberNFC ?? null,
                type: r.extintor?.type ?? null,
                location: r.extintor?.location ?? null,
                fotos: fotosBackend,
                comentarios: r.inspeccionDetalle?.observaciones ?? null,
                fechaHora: r.inspeccionDetalle?.createdAt ?? null
            }
        })
    }
}