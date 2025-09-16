FROM public.ecr.aws/docker/library/python:3.12-slim
WORKDIR /app
COPY app.py /app/
RUN pip install --no-cache-dir fastapi uvicorn[standard] pydantic
ENV PORT=5000 APP_ENV=dev
EXPOSE 5000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
