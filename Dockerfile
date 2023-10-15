FROM debian:trixie as builder

RUN apt-get update  \
    && export DEBIAN_FRONTEND=noninteractive \
    #
    # update certificates
    && apt-get install -y --reinstall ca-certificates \
    # 
    # install curl
    && apt-get install -y --no-install-recommends git curl build-essential \
    #
    # clean-up/
    && apt-get autoremove -y  \
    && apt-get clean -y  \
    && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

ARG JAVA_VERSION=21

ENV LANG=en_US.UTF-8
ENV JAVA_URL=https://download.oracle.com/java/$JAVA_VERSION/archive
ENV	JAVA_HOME=/usr/java/jdk-$JAVA_VERSION
ENV JAVA_VERSION=$JAVA_VERSION

ENV PAPER_PKG=https://api.papermc.io/v2/projects/paper/versions/1.20.2/builds/240/downloads/paper-1.20.2-240.jar
ENV PAPER_HOME=/paper

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# https://github.com/oracle/docker-images/blob/b13849a6b95700de7dc5d401e73a82e8d7a3d009/OracleJava/17/Dockerfile
RUN set -eux; \
    ARCH="$(uname -m)" && \
	# Java uses just x64 in the name of the tarball
    if [ "${ARCH}" = "x86_64" ]; then \
        ARCH="x64"; \
    fi && \
    JAVA_PKG="${JAVA_URL}/jdk-${JAVA_VERSION}_linux-${ARCH}_bin.tar.gz" ; \
	JAVA_SHA256="$(curl "${JAVA_PKG}".sha256)" ; \ 
	curl --output /tmp/jdk.tgz "${JAVA_PKG}" && \
	echo "${JAVA_SHA256}" */tmp/jdk.tgz | sha256sum -c; \
	mkdir -p "${JAVA_HOME}"; \
	tar --extract --file /tmp/jdk.tgz --directory "${JAVA_HOME}" --strip-components 1

# https://docs.papermc.io/paper
RUN mkdir -p "${PAPER_HOME}" \
    && curl --output "${PAPER_HOME}/paper.jar" "${PAPER_PKG}" \
    && echo eula=true > "${PAPER_HOME}/eula.txt"

# https://github.com/Tiiffi/mcrcon
RUN git clone https://github.com/Tiiffi/mcrcon /tmp/mcrcon \
    && cd /tmp/mcrcon \
    && make \
    && make install


FROM debian:trixie

COPY --from=builder $JAVA_HOME $JAVA_HOME
COPY --from=builder $PAPER_HOME $PAPER_HOME

ARG USERNAME=paper
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG JAVA_VERSION=21

ENV LANG=en_US.UTF-8
ENV	JAVA_HOME=/usr/java/jdk-$JAVA_VERSION
ENV PATH=$JAVA_HOME/bin:$PATH	
ENV PAPER_HOME=/paper

# add non-root user
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd -s /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}" \
    && chown -R "${USERNAME}:${USERNAME}" "${PAPER_HOME}"

WORKDIR $PAPER_HOME

USER $USERNAME
