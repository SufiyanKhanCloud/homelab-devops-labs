FROM python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN addgroup -S -g 10001 app \
 && adduser -S -D -H -u 10001 -G app -s /sbin/nologin app

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install --require-hashes -r requirements.txt \
 && python -m pip uninstall -y pip

COPY app.py .

USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=2)" || exit 1

CMD ["gunicorn", "-b", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]
