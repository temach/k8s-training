FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1
ENV OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py app.py

RUN opentelemetry-bootstrap -a install

# set to specify collector address:
# ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 
CMD ["opentelemetry-instrument", "--logs_exporter", "otlp", "flask", "run", "--host=0.0.0.0", "--port=8080"]
