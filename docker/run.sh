# Load environment variables from .env (default) or custom file
ADDITIONAL_ENV_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file|-e)
      ADDITIONAL_ENV_FILE="$2"; shift 2 ;;
    *)
      shift ;;
  esac
done

source "$(dirname "$0")/_init.sh" "$ADDITIONAL_ENV_FILE"

# Use ENV_FILE (set by _init.sh) as the --env-file for docker run#
docker run  --detach  --name "${CONTAINER_NAME}" --publish "${HOST_PORT:-$APP_SERVER_PORT}:${CONTAINER_PORT}" --env-file "$ENV_FILE" "${CONTAINER_IMAGE}:${CONTAINER_TAG}"
