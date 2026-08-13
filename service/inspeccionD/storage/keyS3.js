export function obtenerKeyDesdeS3Url(url) {
    if (!url) return null

    const raw = String(url).trim()
    if (!raw) return null
    if (raw === 'https://...' || raw === 'http://...') return null

    // If the value is already a preview URL, reuse only the key param.
    if (raw.includes('/certificado/preview?')) {
        try {
            const parsed = new URL(raw)
            const key = parsed.searchParams.get('key')
            if (!key) return null
            return obtenerKeyDesdeS3Url(key)
        } catch (error) {
            return null
        }
    }

    const baseUrl = `https://${process.env.S3_BUCKET}.s3.${process.env.S3_REGION}.amazonaws.com/`

    if (raw.startsWith(baseUrl)) {
        return raw.replace(baseUrl, '')
    }

    // Fallback for any Amazon S3 URL shape.
    const marker = '.amazonaws.com/'
    const markerIndex = raw.indexOf(marker)
    if (markerIndex !== -1) {
        return raw.slice(markerIndex + marker.length)
    }

    return raw
}

export function mapExtintorPhoto(item) {
    if (!item) return item;

    let photoPreview = null;

    if (item.photo) {
        const key = obtenerKeyDesdeS3Url(item.photo);
        if (key) {
            photoPreview = `${process.env.API_URL}/certificado/preview?key=${encodeURIComponent(key)}`;
        }
    }

    return {
        ...item,
        photo: photoPreview
    };
}