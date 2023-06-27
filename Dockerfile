# app/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# RUN apt-get update && apt-get install -y \
#     build-essential \
#     curl \
#     software-properties-common \
#     git \
#     nmap \
#     && rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY ./src /app/src

EXPOSE 8081

ENTRYPOINT ["python", "src/main.py"]
