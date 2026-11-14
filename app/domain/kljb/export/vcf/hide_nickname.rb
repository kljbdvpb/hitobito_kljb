# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# vCard-Export ohne NICKNAME-Zeile. Core (Export::Vcf::Vcards#name) schreibt
# card.nickname, sobald person.nickname vorhanden ist; hier nur Vor-/Nachname.
module Kljb::Export::Vcf::HideNickname
  private

  def name(card, person)
    card.name do |n|
      n.given = person.first_name.to_s
      n.family = person.last_name.to_s
    end
  end
end
