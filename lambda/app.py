import boto3
import os
from PIL import Image
import io

s3 = boto3.client("s3")

def lambda_handler(event, context):
    source_bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    # Only process jpg files
    if not key.lower().endswith(".jpg"):
        return

    # Get image from S3
    response = s3.get_object(Bucket=source_bucket, Key=key)
    image_content = response["Body"].read()

    # Remove EXIF metadata
    image = Image.open(io.BytesIO(image_content))
    data = list(image.getdata())

    clean_image = Image.new(image.mode, image.size)
    clean_image.putdata(data)

    buffer = io.BytesIO()
    clean_image.save(buffer, format="JPEG")
    buffer.seek(0)

    destination_bucket = os.environ["DEST_BUCKET"]

    # Upload cleaned image to bucket B
    s3.put_object(
        Bucket=destination_bucket,
        Key=key,
        Body=buffer,
        ContentType="image/jpeg"
    )