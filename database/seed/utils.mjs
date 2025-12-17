export function generateUserCode(number) {
    return `USR-${number.toString().padStart(4, '0')}`
}

export function generateClientCode(number) {
    return `CLI-${number.toString().padStart(4, '0')}`
}