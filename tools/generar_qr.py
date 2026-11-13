import argparse
from pathlib import Path
from urllib.parse import urlparse

import qrcode


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera un QR para descargar el APK de Water Eject."
    )
    parser.add_argument("--url", required=True, help="URL pública HTTPS del APK")
    parser.add_argument(
        "--output",
        default="WaterEject_QR.png",
        help="Ruta de la imagen PNG que se generará",
    )
    args = parser.parse_args()

    parsed_url = urlparse(args.url)
    if parsed_url.scheme != "https" or not parsed_url.netloc:
        parser.error("--url debe ser una URL pública válida que empiece con https://")

    qr = qrcode.QRCode(version=5, box_size=12, border=4)
    qr.add_data(args.url)
    qr.make(fit=True)
    image = qr.make_image(fill_color="black", back_color="white")
    output_path = Path(args.output)
    image.save(output_path)
    print(f"QR creado correctamente: {output_path}")


if __name__ == "__main__":
    main()
