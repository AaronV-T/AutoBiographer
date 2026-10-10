-- Milestones are keyed by level or raid ID, rather than duplicated in history.
CharacterSnapshots = {}

function CharacterSnapshots.New()
  return { Levels = {}, Raids = {} }
end
