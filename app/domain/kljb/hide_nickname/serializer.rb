# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Spitzname in den Legacy-REST-Serialisierern (/groups/:id/people.json, /people/:id.json,
# Kontaktperson, User) weglassen. Die Serializer rufen map_properties :nickname auf;
# der Schluessel wird hier herausgefiltert (kein PUBLIC_ATTRS-Eingriff, siehe Kljb::Person).
module Kljb::HideNickname::Serializer
  def map_properties(*props, &block)
    super(*props.reject { |prop| prop.to_s == 'nickname' }, &block)
  end
end
