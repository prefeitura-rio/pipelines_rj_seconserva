# Build arguments
ARG PYTHON_VERSION=3.10-slim-buster

# Get Oracle Instant Client
FROM curlimages/curl:7.81.0 as curl-step
ARG ORACLE_INSTANT_CLIENT_URL=https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip
RUN curl -sSLo /tmp/instantclient.zip $ORACLE_INSTANT_CLIENT_URL

# Unzip Oracle Instant Client
FROM ubuntu:18.04 as unzip-step
COPY --from=curl-step /tmp/instantclient.zip /tmp/instantclient.zip
RUN apt-get update && \
    apt-get install --no-install-recommends -y unzip && \
    rm -rf /var/lib/apt/lists/* && \
    unzip /tmp/instantclient.zip -d /tmp

# Start Python image
FROM python:${PYTHON_VERSION}

# Install a few dependencies and setup oracle instant client
WORKDIR /opt/oracle
COPY --from=unzip-step /tmp/instantclient_21_5 /opt/oracle/instantclient_21_5
RUN apt-get update && \
    apt-get install --no-install-recommends -y git curl gnupg2 libaio1 && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install --no-install-recommends -y ffmpeg libsm6 libxext6 msodbcsql17 openssl unixodbc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    sh -c "echo /opt/oracle/instantclient_21_5 > /etc/ld.so.conf.d/oracle-instantclient.conf" && \
    ldconfig
COPY ./openssl.cnf /etc/ssl/openssl.cnf

# Setting environment with prefect version
ARG PREFECT_VERSION=1.4.1
ENV PREFECT_VERSION $PREFECT_VERSION

# Setup virtual environment and prefect
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --no-cache-dir -U "pip>=21.2.4" "prefect==$PREFECT_VERSION"

# Install requirements
WORKDIR /app
COPY . .
RUN python3 -m pip install --prefer-binary --no-cache-dir -U .