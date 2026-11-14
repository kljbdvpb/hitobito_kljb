# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb::Person
  extend ActiveSupport::Concern

  # Person#person_name haengt " / Spitzname" an, solange :nickname in PUBLIC_ATTRS steht.
  module HiddenNickname
    def person_name(format = :default)
      full_name(format)
    end
  end

  included do
    # Spitzname in der Oberflaeche ausblenden (Formulare, Filter, Suche, Merge, Namensanzeige).
    # :nickname bleibt bewusst in PUBLIC_ATTRS: Person.only_public_data selektiert genau
    # diese Spalten (person.rb:391), und Core-Code liest nickname weiterhin (person.rb:471,
    # 498, 637; Export::Vcf::Vcards:25). Ohne die Spalte im Select faellt das mit
    # ActiveModel::MissingAttributeError aus (Adressliste, Abos, vCard).
    # Formulare/Anzeige pruefen used_attributes (people/_person_name_fields,
    # roles/_person_fields, label_formats/_form, event/register/_manager_fields).
    Person::MERGABLE_ATTRS.delete(:nickname)
    Person::FILTER_ATTRS.delete(:nickname)
    Person::SEARCHABLE_ATTRS.delete(:nickname)
    self.used_attributes -= [:nickname]
    prepend HiddenNickname
  end

  def underage?(cutoff_date = Time.zone.now.to_date)
    return false unless birthday?

    years(cutoff_date).presence < 18
  end
end
