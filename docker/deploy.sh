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

echo "Use the following command to run the image from the registry:"
#echo "docker run --detach --name ${CONTAINER_NAME} --publish ${HOST_PORT}:${CONTAINER_PORT} --env-file "generated/${ENV_FILE##*/}" ${CONTAINER_REPO}/${CONTAINER_IMAGE}:${REPO_TAG:-${CONTAINER_TAG}}"
# Read each variable from the generated env file and build --env arguments
ENV_ARGS=""
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      key="${line%%=*}"
      value="${line#*=}"
      # Escape special characters in value for shell
      value_escaped=$(printf '%q' "$value")
      if [[ "$key" == "OPTION_INSTALLPATH" ]]; then
        value_escaped=$(printf '%q' "$value" | sed 's|/|\\\\\\/|g')
      fi
      ENV_ARGS+="    --env $key=$value_escaped \\\\\n"
done < "$ENV_FILE"

echo -e "docker run --detach \\\\\n    --name \"${CONTAINER_NAME}\" \\\\\n    --publish \"${HOST_PORT}:${CONTAINER_PORT}\" \\\\\n${ENV_ARGS}    ${CONTAINER_REPO}/${CONTAINER_IMAGE}:${REPO_TAG:-${CONTAINER_TAG}}"