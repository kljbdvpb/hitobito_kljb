class Group::Ortsgruppe < ::Group
  self.layer = true

  self.default_children = [
    Group::OrtsgruppeVorstand,
    Group::OrtsgruppeAg,
    Group::OrtsgruppeKontakte,
    Group::OrtsgruppeLeiterrunde
  ]

  children(*default_children)

  class Foerdermitglied < ::Role
    self.visible_from_above = false
    self.kind = :passive
    self.permissions = []
  end

  class Mitglied < ::Role
    self.permissions = [:group_read]
  end

  roles Foerdermitglied, Mitglied
end
