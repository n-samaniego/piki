-- piki/types.lua
-- Partial (user-facing) type definitions for setup()
-- This file is annotation-only; it exists so LuaLS can discover the partial types.
-- The ", {}" multi-inheritance trick makes all inherited fields optional.

--- @class (exact) piki.Config.Partial : piki.Config, {}
--- @field path? string
--- @field picker? string
--- @field inbox? piki.InboxConfig.Partial
--- @field completion? piki.CompletionConfig.Partial
--- @field wikilinks? piki.WikilinksConfig.Partial
--- @field tags? piki.TagsConfig.Partial
--- @field default_link_style? "markdown"|"wikilink"

--- @class (exact) piki.InboxConfig.Partial : piki.InboxConfig, {}

--- @class (exact) piki.CompletionConfig.Partial : piki.CompletionConfig, {}

--- @class (exact) piki.WikilinksConfig.Partial : piki.WikilinksConfig, {}

--- @class (exact) piki.TagsConfig.Partial : piki.TagsConfig, {}

return {}
