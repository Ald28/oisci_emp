import bcrypt from 'bcrypt'
import { prisma } from '../client.mjs'
import { generateUserCode } from './utils.mjs'

export async function seedUsers(roles) {
    const users = [
        { code: 1, name: 'Administrador', email: 'admin@admin.com', roleId: roles.adminRole.id },
        { code: 2, name: 'Técnico Ejemplo', email: 'tecnico@empresa.com', roleId: roles.tecnicoRole.id },
        { code: 3, name: 'Cliente Ejemplo', email: 'cliente@empresa.com', roleId: roles.clienteRole.id },
    ]

    for (const u of users) {
        await prisma.user.upsert({
            where: { email: u.email },
            update: {},
            create: {
                userCode: generateUserCode(u.code),
                name: u.name,
                email: u.email,
                password: await bcrypt.hash('123456', 10),
                roleId: u.roleId,
            },
        })
    }

    const clienteUser = await prisma.user.findUnique({ where: { email: 'cliente@empresa.com' } })
    return clienteUser
}