# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Listenkoepfe "Nachname | Vorname | Spitzname" (Personen-, Teilnehmer-, Kollegenlisten):
# Spitzname-Spalte (Beschriftung und Sortierlink) ausblenden. Wird auf PeopleHelper geprepended.
module Kljb::HideNickname::PeopleHelper
  def sortable_grouped_person_attr(t, attrs, &block)
    super(t, attrs.except(:nickname), &block)
  end
end
