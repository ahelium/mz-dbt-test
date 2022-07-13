FROM python:3.8-slim

COPY requirements.txt .
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex; \
  	pip install --no-cache-dir -r requirements.txt

ADD metrics.py .
EXPOSE 6875
CMD ["python", "-u", "./metrics.py"]