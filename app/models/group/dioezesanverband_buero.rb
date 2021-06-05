class Group::DioezesanverbandBuero < ::Group
  class Verwaltungsleitung < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Referent < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Sekretariat < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Mitarbeiter < ::Role
    self.permissions = [:layer_and_below_read, :layer_full]
  end

  roles Verwaltungsleitung, Referent, Sekretariat, Mitarbeiter
end
