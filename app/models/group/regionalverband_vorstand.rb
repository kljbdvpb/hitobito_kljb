class Group::RegionalverbandVorstand < ::Group
  class Vorsitz < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Geist < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Finanzverantwortlicher < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class Mitglied < ::Role
    self.permissions = [:layer_full, :layer_and_below_read, :contact_data]
  end

  roles Vorsitz, Geist, Finanzverantwortlicher, Mitglied
end
