Catalogs = {}
function Catalogs.New()
  return {
    UnitCatalog = {}, -- Dict<CatalogUnitId, CatalogUnit>
  }
end

function Catalogs.PrintUnitCatalog(c)
  for k,v in pairs(c.UnitCatalog) do
    print(CatalogUnit.ToString(v))
  end
end

CatalogUnit = {}
function CatalogUnit.New(id, class, classification, creatureFamily, creatureType, name, race)
  return {
    Id = id,
    Class = class,
    Clsfctn = classification,
    CFam = creatureFamily,
    CType = creatureType,
    Name = name,
    Race = race
  }
end

function CatalogUnit.ToString(cu)
  return tostring(cu.Id) .. ", " .. tostring(cu.Name) .. ", "  .. tostring(cu.Class) .. ", " .. tostring(cu.Clsfctn) .. ", " .. tostring(cu.CType) .. ", " .. tostring(cu.CFam) .. ", " .. tostring(cu.Race) .. "."
end