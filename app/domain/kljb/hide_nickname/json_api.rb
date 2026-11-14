# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# JSON:API: Spitzname wird nie ausgeliefert (Wert immer nil). Das Attribut bleibt mit
# unveraenderten Optionen im Graphiti-Schema (spec/support/graphiti/schema.json bleibt gueltig);
# nur der Wert wird durch den Block ersetzt. Betrifft die Person selbst und die
# Kontaktperson in Event::ContactDetailsResource.
module Kljb::HideNickname::JsonApi
  module_function

  def apply!
    PersonResource.attribute :nickname, :string do
      nil
    end

    Event::ContactDetailsResource.attribute :nickname, :string, readable: :name_visible?,
                                                                 writable: false,
                                                                 filterable: false,
                                                                 sortable: false do
      nil
    end
  end
end
