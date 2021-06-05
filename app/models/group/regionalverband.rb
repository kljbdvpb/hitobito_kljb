class Group::Regionalverband < ::Group
  self.layer = true

  self.default_children = [
    Group::RegionalverbandVorstand,
    Group::RegionalverbandAg,
    Group::RegionalverbandKontakte
  ]

  children(*default_children, Group::Ortsgruppe)

  class Foerdermitglied < ::Role
    self.kind = :passive
    self.visible_from_above = false
    self.permissions = []
  end

  roles Foerdermitglied
end
