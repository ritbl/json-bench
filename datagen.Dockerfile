FROM python:3.14-slim

WORKDIR /workdir

ENTRYPOINT ["python", "/workdir/scripts/generate_big_json.py"]
