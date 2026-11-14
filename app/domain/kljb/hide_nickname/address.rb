# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Briefetiketten (PDF): Spitzname nie drucken, auch wenn ein gespeichertes Etikettenformat
# nickname: true hat (Core: Contactable::Address#print_nickname?, privat).
module Kljb::HideNickname::Address
  private

  def print_nickname?(_nickname)
    false
  end
end
