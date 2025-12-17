import bcrypt from 'bcrypt'
import { generateAccessToken, generateRefreshToken, } from '../src/config/jwt.js'
import { AuthRepository } from '../repository/auth.repository.js'
import { prisma } from '../database/client.mjs'

export async function loginService({ email, password }) {

    const user = await AuthRepository.findUserByEmail(email)

    if (!user) throw new Error('Credenciales inválidas')

    if (!user.active) {
        throw new Error('Usuario inactivo')
    }

    const passwordValid = await bcrypt.compare(password, user.password)
    
    if (!passwordValid) throw new Error('Credenciales inválidas')

    if (user.role.name === 'cliente') {
        const client = user.clients[0]
        if (!client || !client.active) {
            throw new Error('Cliente inactivo')
        }
    }

    const permissions = user.role.permissions.map(
        rp => rp.permission.name
    )

    const payload = {
        sub: user.id,
        role: user.role.name,
        permissions,
    }

    const accessToken = generateAccessToken(payload)
    const refreshToken = generateRefreshToken({ sub: user.id })

    await prisma.refreshToken.create({
        data: {
            token: refreshToken,
            userId: user.id,
            expiresAt: new Date(Date.now() + 7 * 86400000),
        },
    })

    return {
        accessToken,
        refreshToken,
        user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role.name,
            permissions,
        },
    }
}