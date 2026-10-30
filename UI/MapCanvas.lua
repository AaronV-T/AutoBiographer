-- Shared tiled map art for the adventure replay and character locations.
AutoBiographer_MapCanvas = {}

local function TextureFileSize(pixels, tileSize)
  if (pixels == tileSize) then return tileSize end
  local size = 16
  while (size < pixels) do size = size * 2 end
  return size
end

function AutoBiographer_MapCanvas.RenderExploration(self)
  for _, tile in ipairs(self.ExplorationTiles) do tile:Hide() end
  if (not self.Layer or not C_MapExplorationInfo or not C_MapExplorationInfo.GetExploredMapTextures) then return end
  local overlays = C_MapExplorationInfo.GetExploredMapTextures(self.MapId)
  local layer, index = self.Layer, 0
  local scaleX, scaleY = self.Map:GetWidth() / layer.layerWidth, self.Map:GetHeight() / layer.layerHeight
  -- Zone map art is a blank outline. Explored subzones are separate, tiled
  -- overlays, using the player's current discoveries (not historical fog).
  for _, overlay in ipairs(overlays or {}) do
    if (not overlay.isShownByMouseOver) then
      local columns = math.ceil(overlay.textureWidth / layer.tileWidth)
      local rows = math.ceil(overlay.textureHeight / layer.tileHeight)
      for row = 1, rows do
        for column = 1, columns do
          local fileId = overlay.fileDataIDs[(row - 1) * columns + column]
          if (fileId) then
            index = index + 1
            local tile = self.ExplorationTiles[index]
            if (not tile) then tile = self.Map:CreateTexture(nil, "ARTWORK"); self.ExplorationTiles[index] = tile end
            local width = math.min(layer.tileWidth, overlay.textureWidth - (column - 1) * layer.tileWidth)
            local height = math.min(layer.tileHeight, overlay.textureHeight - (row - 1) * layer.tileHeight)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (overlay.offsetX + (column - 1) * layer.tileWidth) * scaleX,
              -(overlay.offsetY + (row - 1) * layer.tileHeight) * scaleY)
            tile:SetSize(width * scaleX, height * scaleY)
            tile:SetTexture(fileId)
            tile:SetTexCoord(0, width / TextureFileSize(width, layer.tileWidth), 0, height / TextureFileSize(height, layer.tileHeight))
            tile:SetDrawLayer("ARTWORK", overlay.isDrawOnTopLayer and 1 or 0)
            tile:Show()
          end
        end
      end
    end
  end
end

function AutoBiographer_MapCanvas.Render(self)
  for _, tile in ipairs(self.Tiles) do tile:Hide() end
  for _, tile in ipairs(self.ExplorationTiles) do tile:Hide() end
  self.Layer = nil
  local layers = self.MapId and C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(self.MapId)
  local layer = layers and layers[1]
  local textures = layer and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(self.MapId, 1)
  if (not layer or not textures or #textures == 0 or not layer.layerWidth or layer.layerWidth <= 0 or
    not layer.layerHeight or layer.layerHeight <= 0 or not layer.tileWidth or layer.tileWidth <= 0 or
    not layer.tileHeight or layer.tileHeight <= 0) then
    self.MapMessage:SetText(self.MapId and "Map art unavailable for this location." or "No recorded map location yet.")
    self.MapMessage:Show()
    return
  end
  self.Layer = layer
  self.MapMessage:Hide()
  local width = math.min(self.MapArea:GetWidth(), self.MapArea:GetHeight() * layer.layerWidth / layer.layerHeight)
  local height = width * layer.layerHeight / layer.layerWidth
  self.Map:SetSize(width, height)
  self.Map:ClearAllPoints()
  self.Map:SetPoint("CENTER", self.MapArea, "CENTER")
  local columns = math.ceil(layer.layerWidth / layer.tileWidth)
  for index, fileId in ipairs(textures) do
    local tile = self.Tiles[index]
    if (not tile) then tile = self.Map:CreateTexture(nil, "BACKGROUND"); self.Tiles[index] = tile end
    local left = ((index - 1) % columns) * layer.tileWidth
    local top = math.floor((index - 1) / columns) * layer.tileHeight
    local tileWidth = math.min(layer.tileWidth, layer.layerWidth - left)
    local tileHeight = math.min(layer.tileHeight, layer.layerHeight - top)
    tile:ClearAllPoints()
    tile:SetPoint("TOPLEFT", left / layer.layerWidth * width, -top / layer.layerHeight * height)
    tile:SetSize(tileWidth / layer.layerWidth * width, tileHeight / layer.layerHeight * height)
    tile:SetTexture(fileId)
    -- Last row/column may be padded; crop rather than stretching that padding.
    tile:SetTexCoord(0, tileWidth / layer.tileWidth, 0, tileHeight / layer.tileHeight)
    tile:Show()
  end
  AutoBiographer_MapCanvas.RenderExploration(self)
end

