import { prisma } from '../client.mjs'

export async function seedExtintores() {
    const sede = await prisma.sede.findFirst()
    const creador = await prisma.user.findFirst({
        where: { email: 'admin@admin.com' }
    })

    if (!sede) {
        throw new Error('No existe sede para crear extintores')
    }

    if (!creador) {
        throw new Error('No existe usuario creador')
    }

    const extintores = [
        {
            codeNFC: 'EXT-001',
            serialNumber: 'SN123456',
            type: 'Agua',
            capacity: '10L',
            agent: 'Agua',
            cylinderNumber: 'C-1001',
            location: 'Pasillo principal',
            status: 'OPERATIVO',
            sedeId: sede.id,
            usuarioCreadorId: creador.id,
        },
        {
            codeNFC: 'EXT-002',
            serialNumber: 'SN123457',
            type: 'CO2',
            capacity: '5L',
            agent: 'CO2',
            cylinderNumber: 'C-1002',
            location: 'Oficina administrativa',
            status: 'INOPERATIVO',
            sedeId: sede.id,
            usuarioCreadorId: creador.id,
        }
    ]

    for (const ext of extintores) {
        await prisma.extintor.create({ data: ext })
    }

    console.log('Extintores creados')
}