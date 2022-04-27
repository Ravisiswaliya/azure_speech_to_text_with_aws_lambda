#https://aws.amazon.com/blogs/aws/new-for-aws-lambda-container-image-support/

# Define function directory
ARG FUNCTION_DIR="/function"

FROM python:3.8-buster as build-image

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
    apt-get install -y \
    g++ \
    make \
    cmake \
    unzip \
    libcurl4-openssl-dev


RUN apt-get update
RUN apt-get -y install build-essential libssl-dev libasound2 wget
# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Copy function code
COPY . ${FUNCTION_DIR}


# Install the runtime interface client
RUN pip install \
    --target ${FUNCTION_DIR} \
    awslambdaric

# Multi-stage build: grab a fresh copy of the base image
FROM python:3.8-buster

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

COPY . ${FUNCTION_DIR}

COPY requirements.txt ./

# installing ffmpeg
RUN tar -xf ffmpeg.tar.xz
RUN mv ffmpeg-*-amd64-static/ffmpeg /usr/bin

RUN pip install --no-cache-dir -r requirements.txt

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

ADD ./aws-lambda-rie /usr/bin/aws-lambda-rie
COPY entry.sh /
RUN chmod 755 /usr/bin/aws-lambda-rie /entry.sh
# ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
ENTRYPOINT [ "/entry.sh" ]
CMD ["app.lambda_handler"]
