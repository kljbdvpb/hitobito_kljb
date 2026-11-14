# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb::Event
  extend ActiveSupport::Concern

  included do
    self.role_types = [Event::Role::Leader,
      Event::Role::Teamer,
      Event::Role::Helper,
      Event::Role::Participant]

    # Spitzname ist kein Event-Kontaktattribut mehr (siehe Kljb::Event::ParticipationContactData).
    # Alte Events koennen :nickname noch in required/hidden_contact_attrs gespeichert haben;
    # Core wuerde sie sonst als ungueltig ablehnen (assert_*_contact_attrs_valid).
    before_validation :remove_nickname_from_contact_attrs
  end

  private

  def remove_nickname_from_contact_attrs
    self.required_contact_attrs = required_contact_attrs.reject { |a| a.to_s == 'nickname' }
    self.hidden_contact_attrs = hidden_contact_attrs.reject { |a| a.to_s == 'nickname' }
  end
end
