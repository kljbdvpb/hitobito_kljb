# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb::Person
  extend ActiveSupport::Concern

  included do
    # Spitzname komplett ausblenden. Die Konstanten und used_attributes werden beim
    # Laden der Core-Klasse berechnet, daher werden sie hier gezielt nachgezogen.
    Person::PUBLIC_ATTRS.delete(:nickname)
    Person::MERGABLE_ATTRS.delete(:nickname)
    Person::FILTER_ATTRS.delete(:nickname)
    Person::SEARCHABLE_ATTRS.delete(:nickname)
    self.used_attributes -= [:nickname]
  end

  def underage?(cutoff_date = Time.zone.now.to_date)
    return false unless birthday?

    years(cutoff_date).presence < 18
  end
end
