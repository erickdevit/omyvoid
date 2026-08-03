# Place in each assistant's global skills directory so the Omyvoid skill is available on first install
mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$OMYVOID_PATH/default/omyvoid-skill" ~/.agents/skills/omyvoid
ln -sfn "$OMYVOID_PATH/default/omyvoid-skill" ~/.claude/skills/omyvoid
ln -sfn "$OMYVOID_PATH/default/omyvoid-skill" ~/.codex/skills/omyvoid
ln -sfn "$OMYVOID_PATH/default/omyvoid-skill" ~/.pi/agent/skills/omyvoid
