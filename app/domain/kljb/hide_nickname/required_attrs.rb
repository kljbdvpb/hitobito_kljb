# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Spitzname ist kein Event-Kontaktattribut mehr (Event.possible_contact_attrs, siehe
# Kljb::Event::ParticipationContactData). Alte Events koennen :nickname aber noch in
# required_contact_attrs gespeichert haben; das Feld wird nicht mehr angezeigt und darf
# nicht mehr als Pflichtfeld zaehlen. Wird auf Event::ParticipationContactData und
# Wizards::RegisterNewEventGuestWizard geprepended.
module Kljb::HideNickname::RequiredAttrs
  def required_attrs
    super - [:nickname]
  end
end
