import { prisma } from '../client.mjs'
import { ServiceValid } from '@prisma/client'

export async function seedServicios() {
    const sede = await prisma.sede.findFirst()
    const creador = await prisma.user.findFirst({
        where: { email: 'admin@admin.com' }
    })
    const tecnico = await prisma.user.findFirst({
        where: { email: 'tecnico1@empresa.com' }
    })

    if (!sede) throw new Error('No existe sede para crear servicios')
    if (!creador) throw new Error('No existe usuario creador')
    if (!tecnico) throw new Error('No existe usuario técnico')

    const servicios = [
        {
            type: 'MANTENIMIENTO',
            dateStart: new Date('2024-01-01'),
            dateEnd: null,
            sincronizado: false,
            status: 'EN_PROCESO',
            statusValid: ServiceValid.APROBADO,
            historic: 'Servicio de mantenimiento preventivo',

            sedeId: sede.id,
            userId: tecnico.id,
            usuarioCreadorId: creador.id,
            usuarioActualizadorId: null,
        },
        {
            type: 'INSPECCION',
            dateStart: new Date('2024-01-02'),
            dateEnd: new Date('2024-01-02'),
            sincronizado: true,
            status: 'FINALIZADO',
            statusValid: ServiceValid.APROBADO,
            historic: 'Inspección anual de extintores',

            sedeId: sede.id,
            userId: tecnico.id,
            usuarioCreadorId: creador.id,
            usuarioActualizadorId: creador.id,
        }
    ]

    await prisma.servicio.createMany({
        data: servicios,
        skipDuplicates: true,
    })

    console.log('Servicios creados')
}