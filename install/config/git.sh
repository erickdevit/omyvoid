# Set identification from install inputs
if [[ -n ${OMYVOID_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$OMYVOID_USER_NAME"
fi

if [[ -n ${OMYVOID_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$OMYVOID_USER_EMAIL"
fi
