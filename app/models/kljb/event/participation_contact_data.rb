# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb::Event::ParticipationContactData
  extend ActiveSupport::Concern

  included do
    # Core 2.11.5: Kontaktattribute stehen in Event.possible_contact_attrs
    # (das frühere contact_attrs existiert nicht mehr).
    Event.possible_contact_attrs -= [:nickname]
  end
end
