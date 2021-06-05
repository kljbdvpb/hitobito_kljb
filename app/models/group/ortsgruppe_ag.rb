class Group::OrtsgruppeAg < ::Group
  class Sprecher < ::Role
    self.permissions = [:group_full, :contact_data]
  end

  class Mitglied < ::Role
    self.permissions = [:group_read]
  end

  roles Sprecher, Mitglied
end
