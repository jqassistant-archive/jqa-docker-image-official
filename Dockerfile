FROM debian:buster-slim

ENV jqa_version=1.9.0
ENV jqa_cmdline_sha1=80b678289c3eee575d227bffa5d306ba5c9f4b28
ENV jqa_distfile_prefix=jqassistant-commandline-neo4jv3
ENV jqa_distfile_suffix=distribution.zip

ENV SERVER="https://repo1.maven.org"
ENV PATH_SEGMENT="/maven2/com/buschmais/jqassistant/cli/${jqa_distfile_prefix}/${jqa_version}/"
ENV ARTIFACT="${jqa_distfile_prefix}-${jqa_version}-${jqa_distfile_suffix}"
ENV FULL_URL="${SERVER}${PATH_SEGMENT}${ARTIFACT}"

# The installation of the JRE will fail if the directory created
# below does not exist
# Oliver Fischer, 2020-12-31
#
# See https://github.com/geerlingguy/ansible-role-java/issues/64
RUN mkdir -p -v /usr/share/man/man1/

# https://github.com/hadolint/hadolint/wiki/DL3009
# hadolint ignore=DL3009
RUN set -ex; \
    apt-get -y update

RUN set -ex; \
    apt-get -y install --no-install-recommends \
        ca-certificates=20190110 \
        coreutils=8.30-3 \
        curl=7.64.0-4+deb10u1  \
        unzip=6.0-23+deb10u1

RUN set -ex; \
    apt-get install -y --no-install-recommends \
        default-jre-headless=2:1.11-71

RUN  apt-get clean \
     && rm -rf /var/lib/apt/lists/*

#
# Be a good guy and do all jQAssistant specific stuff as dedicated user
#
RUN set -ex; \
    groupadd -r jqa --gid=11112; \
    useradd -r -g jqa --uid=11112 --home-dir=/opt/jqa --shell=/bin/bash jqa; \
    mkdir -p -v /opt/jqa; \
    chown -R jqa:jqa /opt/jqa

RUN set -ex; \
    mkdir -p /workspace; \
    chown -R jqa:jqa /workspace;

WORKDIR /tmp

RUN set -ex; \
    curl --silent --show-error --output distribution.zip $FULL_URL

RUN set -ex; \
    printf "%s  %s" ${jqa_cmdline_sha1} distribution.zip > check-sums.dat; \
    sha1sum -c check-sums.dat

RUN set -ex; \
    unzip distribution.zip; \
    mv -v ${jqa_distfile_prefix}-${jqa_version}/* /opt/jqa; \
    rm -r -v -f distribution.zip check-sums.dat; \
    chown -R jqa:jqa /opt/jqa

EXPOSE 7473
EXPOSE 7474
EXPOSE 7687

USER jqa

VOLUME ["/workspace"]
WORKDIR /workspace

ENTRYPOINT ["/opt/jqa/bin/jqassistant.sh"]

CMD ["--help"]

