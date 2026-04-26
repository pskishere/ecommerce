FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy project
COPY . .

EXPOSE 8000

# Use Railway's PORT env var
ENV PORT=8000

CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn --bind 0.0.0.0:$PORT --workers 2 ecommerce_dj.wsgi:application"]
