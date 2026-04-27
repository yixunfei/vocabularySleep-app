PRAGMA foreign_keys = ON;

CREATE TABLE daily_choice_recipe_schema_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE daily_choice_recipe_sets (
  set_id TEXT PRIMARY KEY,
  set_kind TEXT NOT NULL CHECK (
    set_kind IN ('builtin', 'remote', 'user', 'collection')
  ),
  title_zh TEXT NOT NULL,
  title_en TEXT NOT NULL,
  description_zh TEXT NOT NULL DEFAULT '',
  description_en TEXT NOT NULL DEFAULT '',
  library_version TEXT NOT NULL DEFAULT '',
  priority INTEGER NOT NULL DEFAULT 0,
  is_enabled INTEGER NOT NULL DEFAULT 1 CHECK (is_enabled IN (0, 1)),
  is_readonly INTEGER NOT NULL DEFAULT 1 CHECK (is_readonly IN (0, 1)),
  recipe_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE daily_choice_recipes (
  recipe_id TEXT PRIMARY KEY,
  primary_set_id TEXT NOT NULL,
  title_zh TEXT NOT NULL,
  title_en TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  primary_meal_id TEXT NOT NULL DEFAULT 'all',
  primary_tool_id TEXT,
  sort_key TEXT NOT NULL,
  random_key INTEGER NOT NULL CHECK (random_key >= 0),
  quality_score INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'disabled', 'deleted')
  ),
  is_available INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (primary_set_id)
    REFERENCES daily_choice_recipe_sets(set_id)
    ON DELETE RESTRICT
);

CREATE TABLE daily_choice_recipe_summaries (
  recipe_id TEXT PRIMARY KEY,
  subtitle_zh TEXT NOT NULL DEFAULT '',
  subtitle_en TEXT NOT NULL DEFAULT '',
  tags_zh_json TEXT NOT NULL DEFAULT '[]',
  tags_en_json TEXT NOT NULL DEFAULT '[]',
  summary_attributes_json TEXT NOT NULL DEFAULT '{}',
  display_badges_json TEXT NOT NULL DEFAULT '[]',
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
);

CREATE TABLE daily_choice_recipe_details (
  recipe_id TEXT PRIMARY KEY,
  details_zh TEXT NOT NULL DEFAULT '',
  details_en TEXT NOT NULL DEFAULT '',
  materials_zh_json TEXT NOT NULL DEFAULT '[]',
  materials_en_json TEXT NOT NULL DEFAULT '[]',
  steps_zh_json TEXT NOT NULL DEFAULT '[]',
  steps_en_json TEXT NOT NULL DEFAULT '[]',
  notes_zh_json TEXT NOT NULL DEFAULT '[]',
  notes_en_json TEXT NOT NULL DEFAULT '[]',
  raw_payload_json TEXT NOT NULL DEFAULT '{}',
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
);

CREATE TABLE daily_choice_recipe_materials (
  recipe_id TEXT NOT NULL,
  material_index INTEGER NOT NULL,
  material_text TEXT NOT NULL,
  normalized_text TEXT NOT NULL,
  material_role TEXT NOT NULL DEFAULT 'ingredient' CHECK (
    material_role IN ('ingredient', 'seasoning', 'tool', 'note')
  ),
  amount_text TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (recipe_id, material_index),
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE daily_choice_recipe_steps (
  recipe_id TEXT NOT NULL,
  step_index INTEGER NOT NULL,
  step_text TEXT NOT NULL,
  normalized_text TEXT NOT NULL,
  PRIMARY KEY (recipe_id, step_index),
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE daily_choice_recipe_filter_index (
  recipe_id TEXT NOT NULL,
  set_id TEXT NOT NULL,
  term_group TEXT NOT NULL,
  term_value TEXT NOT NULL,
  confidence INTEGER NOT NULL DEFAULT 100 CHECK (
    confidence >= 0 AND confidence <= 100
  ),
  source_kind TEXT NOT NULL DEFAULT 'generated' CHECK (
    source_kind IN ('source', 'generated', 'user')
  ),
  PRIMARY KEY (recipe_id, term_group, term_value, set_id),
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE,
  FOREIGN KEY (set_id)
    REFERENCES daily_choice_recipe_sets(set_id)
    ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE daily_choice_recipe_ingredient_index (
  recipe_id TEXT NOT NULL,
  set_id TEXT NOT NULL,
  token_kind TEXT NOT NULL CHECK (
    token_kind IN ('raw', 'canonical', 'family')
  ),
  token_value TEXT NOT NULL,
  display_text TEXT NOT NULL DEFAULT '',
  source_text TEXT NOT NULL DEFAULT '',
  match_level INTEGER NOT NULL DEFAULT 80 CHECK (
    match_level >= 0 AND match_level <= 100
  ),
  is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
  source_kind TEXT NOT NULL DEFAULT 'generated' CHECK (
    source_kind IN ('source', 'generated', 'user')
  ),
  PRIMARY KEY (recipe_id, token_kind, token_value, set_id),
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE,
  FOREIGN KEY (set_id)
    REFERENCES daily_choice_recipe_sets(set_id)
    ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE daily_choice_recipe_search_text (
  recipe_id TEXT PRIMARY KEY,
  search_title TEXT NOT NULL,
  search_materials TEXT NOT NULL DEFAULT '',
  search_tags TEXT NOT NULL DEFAULT '',
  search_all TEXT NOT NULL,
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
);

CREATE TABLE daily_choice_recipe_user_state (
  recipe_id TEXT PRIMARY KEY,
  is_hidden INTEGER NOT NULL DEFAULT 0 CHECK (is_hidden IN (0, 1)),
  is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1)),
  local_is_available INTEGER CHECK (local_is_available IN (0, 1)),
  user_note TEXT NOT NULL DEFAULT '',
  last_viewed_at TEXT,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
);

CREATE TABLE daily_choice_recipe_user_collections (
  collection_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE daily_choice_recipe_user_collection_members (
  collection_id TEXT NOT NULL,
  recipe_id TEXT NOT NULL,
  added_at TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (collection_id, recipe_id),
  FOREIGN KEY (collection_id)
    REFERENCES daily_choice_recipe_user_collections(collection_id)
    ON DELETE CASCADE,
  FOREIGN KEY (recipe_id)
    REFERENCES daily_choice_recipes(recipe_id)
    ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE daily_choice_recipe_set_stats (
  set_id TEXT PRIMARY KEY,
  active_recipe_count INTEGER NOT NULL DEFAULT 0,
  disabled_recipe_count INTEGER NOT NULL DEFAULT 0,
  ingredient_term_count INTEGER NOT NULL DEFAULT 0,
  filter_term_count INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (set_id)
    REFERENCES daily_choice_recipe_sets(set_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_dcr_sets_enabled_priority
  ON daily_choice_recipe_sets(is_enabled, priority, set_id);

CREATE INDEX idx_dcr_recipes_active_set_sort
  ON daily_choice_recipes(primary_set_id, sort_key, recipe_id)
  WHERE is_available = 1 AND status = 'active';

CREATE INDEX idx_dcr_recipes_active_set_random
  ON daily_choice_recipes(primary_set_id, random_key, recipe_id)
  WHERE is_available = 1 AND status = 'active';

CREATE INDEX idx_dcr_recipes_title
  ON daily_choice_recipes(normalized_title, recipe_id);

CREATE INDEX idx_dcr_recipes_meal_tool
  ON daily_choice_recipes(primary_meal_id, primary_tool_id, recipe_id)
  WHERE is_available = 1 AND status = 'active';

CREATE INDEX idx_dcr_materials_lookup
  ON daily_choice_recipe_materials(normalized_text, recipe_id);

CREATE INDEX idx_dcr_filter_lookup
  ON daily_choice_recipe_filter_index(
    term_group,
    term_value,
    set_id,
    recipe_id
  );

CREATE INDEX idx_dcr_filter_recipe
  ON daily_choice_recipe_filter_index(recipe_id, term_group, term_value);

CREATE INDEX idx_dcr_ingredient_lookup
  ON daily_choice_recipe_ingredient_index(
    token_kind,
    token_value,
    set_id,
    match_level DESC,
    recipe_id
  );

CREATE INDEX idx_dcr_ingredient_value_lookup
  ON daily_choice_recipe_ingredient_index(
    token_value,
    set_id,
    match_level DESC,
    recipe_id,
    token_kind
  );

CREATE INDEX idx_dcr_ingredient_recipe
  ON daily_choice_recipe_ingredient_index(
    recipe_id,
    token_kind,
    token_value
  );

CREATE INDEX idx_dcr_ingredient_primary
  ON daily_choice_recipe_ingredient_index(set_id, token_value, recipe_id)
  WHERE is_primary = 1;

CREATE INDEX idx_dcr_search_title
  ON daily_choice_recipe_search_text(search_title, recipe_id);

CREATE INDEX idx_dcr_user_state_hidden
  ON daily_choice_recipe_user_state(is_hidden, recipe_id)
  WHERE is_hidden = 1;

CREATE INDEX idx_dcr_user_state_favorite
  ON daily_choice_recipe_user_state(is_favorite, recipe_id)
  WHERE is_favorite = 1;

CREATE INDEX idx_dcr_collection_members_recipe
  ON daily_choice_recipe_user_collection_members(recipe_id, collection_id);

CREATE INDEX idx_dcr_collection_members_order
  ON daily_choice_recipe_user_collection_members(
    collection_id,
    sort_order,
    recipe_id
  );

CREATE INDEX idx_dcr_set_stats_active
  ON daily_choice_recipe_set_stats(active_recipe_count, set_id);
