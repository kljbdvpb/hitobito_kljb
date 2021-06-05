class Group::OrtsgruppeLeiterrunde < ::Group
  class Leiter < ::Role
    self.permissions = [:layer_and_below_read]
  end

  roles Leiter
end
