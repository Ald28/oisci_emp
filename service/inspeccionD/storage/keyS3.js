export function obtenerKeyDesdeS3Url(url) {
    if (!url) return null

    const baseUrl = `https://${process.env.S3_BUCKET}.s3.${process.env.S3_REGION}.amazonaws.com/`

    if (url.startsWith(baseUrl)) {
        return url.replace(baseUrl, '')
    }

    return url
}

export function mapExtintorPhoto(item) {
    if (!item) return item;

    let photoPreview = null;

    if (item.photo) {
        const key = obtenerKeyDesdeS3Url(item.photo);
        photoPreview = `${process.env.API_URL}/certificado/preview?key=${encodeURIComponent(key)}`;
    }

    return {
        ...item,
        photo: photoPreview
    };
}