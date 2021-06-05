class Group::DioezesanverbandVorstand < ::Group
  class Seelsorger < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Vorstand < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Beratend < ::Role
    self.permissions = [:layer_read]
  end

  roles Seelsorger, Vorstand, Beratend
end
