import jwt from 'jsonwebtoken'

export function authenticate(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.sendStatus(401)

    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET)
        next()
    } catch {
        res.sendStatus(401)
    }
}

export function authorize(allowedRoles = []) {
    return (req, res, next) => {
        if (!allowedRoles.length) return next()

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ message: 'No tienes permisos' })
        }

        next()
    }
}