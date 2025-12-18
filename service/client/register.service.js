import bcrypt from 'bcrypt'
import { RegisterRepository } from '../../repository/client/register.repository.js'
import { prisma } from '../../database/client.mjs'

export async function registerUserService(adminUser, userData) {

    if (adminUser.role !== 'admin') {
        throw new Error('No tienes permisos para registrar usuarios')
    }

    const existingUser = await RegisterRepository.findUserByEmail(userData.email)
    if (existingUser) {
        throw new Error('El email ya está registrado')
    }

    if (userData.roleName === 'cliente') {
        if (!userData.ruc) {
            throw new Error('El RUC es obligatorio para usuarios cliente')
        }
        if (typeof userData.ruc !== 'string' || userData.ruc.length !== 11) {
            throw new Error('El RUC debe ser una cadena de 11 caracteres')
        }

        const existingClient = await prisma.client.findUnique({ where: { ruc: userData.ruc } })
        if (existingClient) {
            throw new Error('El RUC ya está registrado')
        }
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10)

    try {
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
                phone: userData.phone,
                address: userData.address,
                userId: user.id,
                active: true,
            })
        }

        return user
    } catch (error) {
        if (error.code === 'P2002') {
            if (error.meta.target.includes('email')) {
                throw new Error('El email ya está registrado')
            }
            if (error.meta.target.includes('ruc')) {
                throw new Error('El RUC ya está registrado')
            }
        }
        throw error
    }

}