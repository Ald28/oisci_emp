// utils/datetime.js

const isValidDate = (value) => {
    if (!value) return false
    const d = new Date(value)
    return d instanceof Date && !Number.isNaN(d.getTime())
}

// ===============================
// Para PDF / UI: "25/02/2026, 18:47:55"
// ===============================
export const toPeruDateTime = (date, empty = '-') => {
    if (!isValidDate(date)) return empty

    return new Intl.DateTimeFormat('es-PE', {
        timeZone: 'America/Lima',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
    }).format(new Date(date))
}

// ===============================
// Para PDF / UI: "25/02/2026"
// ===============================
export const toPeruDate = (date, empty = '-') => {
    if (!isValidDate(date)) return empty

    return new Intl.DateTimeFormat('es-PE', {
        timeZone: 'America/Lima',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    }).format(new Date(date))
}

// ===============================
// Para API / Flutter: ISO parseable con -05:00
// Ej: "2026-02-25T18:47:55.521-05:00"
// ===============================
export const toPeruIso = (date) => {
    if (!isValidDate(date)) return null

    const d = new Date(date)

    // Perú UTC-5 fijo (sin DST)
    const peruOffsetMs = 5 * 60 * 60 * 1000
    const peruTime = new Date(d.getTime() - peruOffsetMs)

    return peruTime.toISOString().replace('Z', '-05:00')
}