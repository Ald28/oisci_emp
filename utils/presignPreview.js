import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

const s3 = new S3Client({
    region: process.env.S3_REGION,
    credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY,
        secretAccessKey: process.env.S3_SECRET_KEY,
    },
})

export async function presignPreview(
    key,
    filename,
    expiresInSec = 600
) {
    const cmd = new GetObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: key,
    })

    return getSignedUrl(s3, cmd, { expiresIn: expiresInSec })
}