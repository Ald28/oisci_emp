import { prisma } from '../client.mjs'

export async function seedRoles() {
    const roles = ['admin', 'tecnico', 'cliente']

    for (const name of roles) {
        await prisma.role.upsert({
            where: { name },
            update: {},
            create: { name },
        })
    }

    const adminRole = await prisma.role.findUnique({ where: { name: 'admin' } })
    const tecnicoRole = await prisma.role.findUnique({ where: { name: 'tecnico' } })
    const clienteRole = await prisma.role.findUnique({ where: { name: 'cliente' } })

    if (!adminRole || !tecnicoRole || !clienteRole) {
        throw new Error('Roles no encontrados')
    }

    return { adminRole, tecnicoRole, clienteRole }
}