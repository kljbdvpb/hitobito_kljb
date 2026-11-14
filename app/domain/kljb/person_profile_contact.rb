# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Kontakt-Wrapper fuer das Personenprofil (app/views/people/_contact_data.html.haml).
# Das Core-Partial contactable/_contact_data rendert die Postanschrift ueber
# contact.complete_address und contact.all_additional_addresses; beide liefern hier
# nichts. Name, E-Mail, Telefon und Social Accounts werden unveraendert durchgereicht.
# Listen (Personenliste, Kollegen, Teilnehmer) nutzen die Decorator-Methoden direkt und
# sind nicht betroffen.
class Kljb::PersonProfileContact < SimpleDelegator
  def complete_address
    ''.html_safe
  end

  def all_additional_addresses(*)
    ''.html_safe
  end
end
