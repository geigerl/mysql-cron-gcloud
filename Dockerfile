FROM python:3.13-alpine AS builder

RUN apk --update add --no-cache curl      
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt .
RUN pip install --root-user-action=ignore --no-cache-dir --upgrade pip \
    && pip install --root-user-action=ignore --no-cache-dir -r requirements.txt

ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.34/supercronic-linux-amd64
ARG SUPERCRONIC_SHA1SUM=e8631edc1775000d119b70fd40339a7238eece14
ARG SUPERCRONIC_BIN=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC_BIN}" | sha1sum -c - \
    && chmod +x "${SUPERCRONIC_BIN}" \
    && mv "${SUPERCRONIC_BIN}" "$VIRTUAL_ENV/bin/supercronic"


FROM python:3.13-alpine
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH" \
    TARGET_USER="appuser" \
    TARGET_GROUP="appgroup" \
    TARGET_UID=6969 \
    TARGET_GID=6969

RUN addgroup -g ${TARGET_GID} -S ${TARGET_GROUP} \
    && adduser -u ${TARGET_UID} -S -G appgroup ${TARGET_USER}     

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv

COPY --chown=${TARGET_UID}:${TARGET_GID} \
     backup.py \
     entrypoint.sh \
     ./

RUN chmod u+x backup.py entrypoint.sh && chown ${TARGET_UID}:${TARGET_GID} /app

ENTRYPOINT ["./entrypoint.sh"]
