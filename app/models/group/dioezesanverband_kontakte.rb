class Group::DioezesanverbandKontakte < ::Group
  class Kontakt < ::Role
    self.kind = :external
    self.visible_from_above = false
    self.permissions = []
  end

  class Teamer < ::Role
    self.kind = :external
    self.visible_from_above = false
    self.permissions = []
  end

  roles Kontakt, Teamer
end
