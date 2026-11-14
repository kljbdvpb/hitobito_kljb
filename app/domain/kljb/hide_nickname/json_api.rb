# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# JSON:API: Spitzname wird nie ausgeliefert (Wert immer nil). Das Attribut bleibt mit
# unveraenderten Optionen im Graphiti-Schema (spec/support/graphiti/schema.json bleibt gueltig);
# nur der Wert wird durch den Block ersetzt. Betrifft die Person selbst und die
# Kontaktperson in Event::ContactDetailsResource. Auf PersonResource ist nickname zusaetzlich
# weder filter- noch sortier- noch schreibbar. Folge: das Wagon-Schema spec/support/graphiti/
# schema.json (Kopie des Core-Stands, Spec mangels app/resources uebersprungen) weicht bei
# PersonResource ab (writable false, kein Filter/Sort nickname), siehe docs.
module Kljb::HideNickname::JsonApi
  module_function

  def apply!
    # nicht filter-, sortier- oder schreibbar (sonst Such-Orakel trotz Wert nil); alte
    # Filter-/Sortier-Registrierungen des Core werden explizit entfernt.
    PersonResource.attribute :nickname, :string, writable: false, filterable: false,
                                                 sortable: false do
      nil
    end
    PersonResource.config[:filters]&.delete(:nickname)
    PersonResource.config[:sorts]&.delete(:nickname)

    Event::ContactDetailsResource.attribute :nickname, :string, readable: :name_visible?,
                                                                 writable: false,
                                                                 filterable: false,
                                                                 sortable: false do
      nil
    end
  end
end
