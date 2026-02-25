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

CONTAINER_IMAGE=${CONTAINER_REPO}/${CONTAINER_IMAGE}
CONTAINER_TAG=${REPO_TAG:-${CONTAINER_TAG:-${APP_VERSION}}}
CONTAINER_PORT=${CONTAINER_PORT:-$APP_SERVER_PORT}
HOST_PORT=${HOST_PORT:-${CONTAINER_PORT:-$APP_SERVER_PORT}}
VOL_LIST=""
VOL_PARAMS=""
ENV_LIST=""
ENV_PARAMS=""
while read -r key; do
  [[ -z "$key" ]] && continue
  eval "value=\$$key"
  value_escaped=$(printf '%s' "$value" | sed -e 's/[\/&]/\\&/g' -e 's/\\/\\\\/g')
  ENV_LIST+="      - $key=$value"$'\\n'
  value_escaped=$(printf '%q' "$value" | sed 's|^/|\\\\\\/|g')
  ENV_PARAMS+="    --env $key=$value_escaped \\"$'\n'
done < <(grep -hv '^#' "${SOURC_ENV_FILE[@]}" | cut -d= -f1 | sort -u)

sed \
  -e "s|__CONTAINER_GROUP__|${CONTAINER_GROUP}|g" \
  -e "s|__CONTAINER_NAME__|${CONTAINER_NAME}|g" \
  -e "s|__CONTAINER_IMAGE__|${CONTAINER_IMAGE}|g" \
  -e "s|__CONTAINER_TAG__|${CONTAINER_TAG}|g" \
  -e "s|__CONTAINER_RESTART__|${CONTAINER_RESTART}|g" \
  -e "s|__CONTAINER_PORT__|${CONTAINER_PORT}|g" \
  -e "s|__HOST_PORT__|${HOST_PORT}|g" \
  -e "s|__ENV_LIST__|$ENV_LIST|g" \
  -e "s|__VOL_LIST__|$VOL_LIST|g" \
  "$TEMPLATE_FILE" > "$YAML_FILE"

echo "Use the following command to run the container ${CONTAINER_NAME} from image ${CONTAINER_IMAGE}:${CONTAINER_TAG}..."
echo "docker-compose --file \"${YAML_FILE}\" up --detach"
#echo -e "docker run --detach \\\\\n    --name \"${CONTAINER_NAME}\" \\\\\n    --publish ${HOST_PORT}:${CONTAINER_PORT} \\\\\n    --restart ${CONTAINER_RESTART} \\\\\n${ENV_PARAMS}${VOL_PARAMS}    \"${CONTAINER_IMAGE}:${CONTAINER_TAG}\""
