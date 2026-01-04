FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir pandas
RUN pip install --no-cache-dir geohash2

COPY geohash.py /app/geohash.py
COPY process.py /app/process.py
COPY download.sh /app/download.sh
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/download.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
