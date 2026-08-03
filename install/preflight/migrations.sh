OMYVOID_MIGRATIONS_STATE_PATH=~/.local/state/omyvoid/migrations
mkdir -p $OMYVOID_MIGRATIONS_STATE_PATH

for file in "$OMYVOID_PATH"/migrations/*.sh; do
  touch "$OMYVOID_MIGRATIONS_STATE_PATH/$(basename "$file")"
done
