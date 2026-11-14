# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Entfernt Authentifizierungs- und Transport-Header des Originalabsenders, bevor
# eine Mail ueber einen Verteiler (MailRelay::Lists) weitergeleitet wird.
#
# Hintergrund: Nach dem Relay (neuer Envelope-Sender, neuer Versandweg ueber Brevo)
# sind DKIM-Signatur, SPF-/ARC-Ergebnisse und Authentication-Results des
# Originalabsenders ohnehin wertlos. Brevo fuehrt beim Einlesen doppelte Header
# zusammen und beschaedigt sie dabei; web.de/GMX bewerten das als
# dkim=permerror und lehnen die Mail ab (451 r0110).
#
# Entfernt werden zusaetzlich zu X-DSPAM (Core, Encoding-Probleme):
#   DKIM-Signature, ARC-*, Authentication-Results, Received-SPF,
#   X-MS-*, X-Microsoft-*, X-Forefront-*, X-Exchange-*, X-Originatororg,
#   Thread-Index, Thread-Topic.
# Die Autorisierung (Absenderpruefung, Verteiler-Berechtigung) laeuft in
# MailRelay::Lists ueber Envelope/From, nicht ueber diese Header; die Aenderung
# betrifft nur die ausgehende Nachricht.
module Kljb::MailRelay::StripAuthHeaders
  STRIPPED_HEADERS = /\A(X-DSPAM|DKIM-Signature|ARC-|Authentication-Results|Received-SPF|
    X-MS-|X-Microsoft-|X-Forefront-|X-Exchange-|X-Originatororg|Thread-Index|Thread-Topic)/ix

  private

  # Ueberschreibt MailRelay::Lists#strip_spam_headers (Core 2.11.5, lists.rb),
  # das im Konstruktor vor super(message) aufgerufen wird.
  def strip_spam_headers(message)
    message.header
      .select { |field| field.name =~ STRIPPED_HEADERS }
      .map(&:name).uniq
      .each { |name| message.header[name] = nil }
  end
end
