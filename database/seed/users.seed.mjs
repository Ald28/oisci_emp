import bcrypt from 'bcrypt'
import { prisma } from '../client.mjs'
import { generateUserCode } from './utils.mjs'

export async function seedUsers(roles) {
    const users = [
        { code: 1, name: 'Administrador', email: 'admin@admin.com', roleId: roles.adminRole.id },
        { code: 2, name: 'Administrador2', email: 'admin2@admin.com', roleId: roles.adminRole.id },
        { code: 3, name: 'Técnico 1', email: 'tecnico1@empresa.com', roleId: roles.tecnicoRole.id },
        { code: 4, name: 'Técnico 2', email: 'tecnico2@empresa.com', roleId: roles.tecnicoRole.id },
        { code: 5, name: 'Cliente 1', email: 'cliente1@empresa.com', roleId: roles.clienteRole.id },
        { code: 6, name: 'Cliente 2', email: 'cliente2@empresa.com', roleId: roles.clienteRole.id },
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

    return prisma.user.findMany({
        where: { role: { name: 'cliente' } }
    })
}