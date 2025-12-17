import bcrypt from 'bcrypt'
import { RegisterRepository } from '../repository/register.repository.js'
import { prisma } from '../database/client.mjs'

export async function registerUserService(adminUser, userData) {
    
    if (adminUser.role !== 'admin') {
        throw new Error('No tienes permisos para registrar usuarios')
    }

    const existingUser = await RegisterRepository.findUserByEmail(userData.email)
    if (existingUser) {
        throw new Error('El email ya está registrado')
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10)

    const user = await RegisterRepository.createUser({
        userCode: `USR-${Date.now()}`,
        name: userData.name,
        email: userData.email,
        password: hashedPassword,
        roleId: userData.roleId,
        active: true,
    })

    if (userData.roleName === 'cliente') {
        await RegisterRepository.createClient({
            clientCode: `CLI-${Date.now()}`,
            razonSocial: userData.razonSocial,
            ruc: userData.ruc,
            userId: user.id,
            active: true,
        })
    }

    return user
}