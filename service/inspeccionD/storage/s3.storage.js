import {
  S3Client, PutObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { randomUUID } from "crypto";
import StorageProvider from "./storage.interface.js";

const s3 = new S3Client({
  region: process.env.S3_REGION,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY,
    secretAccessKey: process.env.S3_SECRET_KEY,
  },
});

export default class S3Storage extends StorageProvider {
  async upload(buffer, options = {}) {
    const fileKey = `${options.folder || "inspecciones"}/${randomUUID()}.jpg`;

    await s3.send(
      new PutObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: fileKey,
        Body: buffer,
        ContentType: "image/jpeg",
      })
    );

    const url = `https://${process.env.S3_BUCKET}.s3.${process.env.S3_REGION}.amazonaws.com/${fileKey}`;

    return {
      url,
      id: fileKey,
    };
  }

  async delete(id) {
    await s3.send(
      new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: id,
      })
    );
  }
}