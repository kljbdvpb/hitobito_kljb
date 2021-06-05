class Group::RegionalverbandKontakte < ::Group
  class Kontakt < ::Role
    self.visible_from_above = false
    self.kind = :external
    self.permissions = []
  end

  roles Kontakt
end
