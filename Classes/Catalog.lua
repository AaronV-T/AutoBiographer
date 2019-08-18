-- *** Catalogs ***

Catalogs = {}
function Catalogs.New()
  return {
    SubZoneCatalog = {}, -- Dict<CatalogSubZoneName, CatalogSubZone>
    SpellCatalog = {}, -- Dict<CatalogSpellId, CatalogSpell>
    UnitCatalog = {}, -- Dict<CatalogUnitId, CatalogUnit>
    ZoneCatalog = {}, -- Dict<CatalogZoneName, CatalogZone>
  }
end

function Catalogs.PlayerHasKilledUnit(catalogs, catalogUnitId)
  local catalogUnit = catalogs.UnitCatalog[catalogUnitId]
  return catalogUnit ~= nil and catalogUnit.Killed
end

function Catalogs.PrintUnitCatalog(catalogs)
  for k,v in pairs(catalogs.UnitCatalog) do
    print(CatalogUnit.ToString(v))
  end
end

-- *** CatalogUnit ***

CatalogUnit = {}
function CatalogUnit.New(id, class, classification, creatureFamily, creatureType, name, race, playerHasKilled)
  return {
    Id = id,
    Class = class,
    Clsfctn = classification,
    CFam = creatureFamily,
    CType = creatureType,
    Name = name,
    Race = race,
    Killed = playerHasKilled
  }
end

function CatalogUnit.ToString(cu)
  return tostring(cu.Id) .. ", " .. tostring(cu.Name) .. ", "  .. tostring(cu.Class) .. ", " .. tostring(cu.Clsfctn) .. ", " .. tostring(cu.CType) .. ", " .. tostring(cu.CFam) .. ", " .. tostring(cu.Race)
end

function CatalogUnit.Update(cu, id, class, classification, creatureFamily, creatureType, name, race, playerHasKilled)
  if (id ~= nil) then cu.Id = id end
  if (class ~= nil) then cu.Class = class end
  if (classification ~= nil) then cu.Clsfctn = classification end
  if (creatureFamily ~= nil) then cu.CFam = creatureFamily end
  if (creatureType ~= nil) then cu.CType = creatureType end
  if (name ~= nil) then cu.Name = Name end
  if (race ~= nil) then cu.Race = Race end
  if (playerHasKilled ~= nil) then cu.Killed = playerHasKilled end
end

-- *** CatalogSpell ***

CatalogSpell = {}
function CatalogSpell.New(id, name, rank)
  return {
    Id = id,
    Name = name,
    Rank = rank
  }
end

-- *** CatalogSubZone ***

CatalogSubZone = {}
function CatalogSubZone.New(name, hasEntered, zoneName)
  return {
    Name = name,
    HasEntered = hasEntered,
    ZoneName = zoneName
  }
end

-- *** CatalogZone ***

CatalogZone = {}
function CatalogZone.New(name, hasEntered)
  return {
    Name = name,
    HasEntered = hasEntered
  }
end

