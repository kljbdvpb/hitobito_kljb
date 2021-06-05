class Group::Dioezesanverband < ::Group
  self.layer = true

  self.default_children = [
    Group::DioezesanverbandVorstand,
    Group::DioezesanverbandBuero,
    Group::DioezesanverbandAg,
    Group::DioezesanverbandKontakte
  ]

  children(*default_children, Group::Regionalverband)

  class Foerdermitglied < ::Role
    self.kind = :passive
    self.permissions = []
  end

  class ItSupport < ::Role
    self.permissions = [:admin, :impersonation, :layer_and_below_full]
  end

  roles Foerdermitglied, ItSupport
end
