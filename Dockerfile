# WARNING: THIS FILE IS MANAGED IN THE 'BOILERPLATE' REPO AND COPIED TO OTHER REPOSITORIES.
# ONLY EDIT THIS FILE FROM WITHIN THE 'LYFT/BOILERPLATE' REPOSITORY:
# 
# TO OPT OUT OF UPDATES, SEE https://github.com/lyft/boilerplate/blob/master/Readme.rst

# Using go1.10.4
FROM golang:1.10.4-alpine3.8 as builder
RUN apk add git openssh-client make curl bash

# COPY only the dep files for efficient caching
COPY Gopkg.* /go/src/github.com/lyft/flinkk8soperator/
WORKDIR /go/src/github.com/lyft/flinkk8soperator

# Pull dependencies
ARG SSH_PRIVATE_KEY
# Temporary: We need github credentials in order to install private repos.
# These repos will be public soon. Then this line can just be "glide install"
RUN : \
  && mkdir /root/.ssh/ \
  && echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa \
  && chmod 400 /root/.ssh/id_rsa \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts \
  && curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh \
  && dep ensure -vendor-only \
  && rm /root/.ssh/id_rsa

# COPY the rest of the source code
COPY . /go/src/github.com/lyft/flinkk8soperator/

# This 'linux_compile' target should compile binaries to the /artifacts directory
# The main entrypoint should be compiled to /artifacts/flinkk8soperator
RUN make linux_compile

# update the PATH to include the /artifacts directory
ENV PATH="/artifacts:${PATH}"

# This will eventually move to centurylink/ca-certs:latest for minimum possible image size
FROM alpine:3.8
COPY --from=builder /artifacts /bin
CMD ["flinkoperator"]
