export async function generarNumeroCertificado(tipo) {
    const year = new Date().getFullYear()

    const ultimo = await prisma.certificado.findFirst({
        where: { tipo },
        orderBy: { createdAt: 'desc' }
    })

    let correlativo = 1
    if (ultimo) {
        const partes = ultimo.numeroCertificado.split('-')
        correlativo = parseInt(partes[2]) + 1
    }

    return `${tipo}-${year}-${String(correlativo).padStart(6, '0')}`
}