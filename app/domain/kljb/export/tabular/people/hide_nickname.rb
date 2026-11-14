# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Spitzname aus den Personen-Exporten (Adressliste, vollstaendiger Export) ausblenden.
# Wird auf Export::Tabular::People::PeopleAddress und ::PeopleFull geprepended, da
# PeopleFull die Spalten zusaetzlich aus Person.column_names aufbaut.
module Kljb::Export::Tabular::People::HideNickname
  def person_attributes
    super - [:nickname]
  end
end
