# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Entfernt Authentifizierungs- und Transport-Header des Originalabsenders, bevor
# eine Mail ueber einen Verteiler weitergeleitet wird.
#
# Hintergrund: Nach dem Relay (neuer Envelope-Sender, anderer Versandweg) sind
# DKIM-Signatur, SPF-/ARC-Ergebnisse und Authentication-Results des
# Originalabsenders wertlos. Beim Einlesen durch den ausgehenden Relay werden
# doppelte Header zusammengefuehrt und dabei beschaedigt; web.de/GMX bewerten das
# als dkim=permerror und lehnen die Mail ab (451 r0110).
# OFFEN: Welcher Relay das ist, ist nicht belegt. docs/status-quo.md nennt
# hitobito -> post.kljb-paderborn.de -> Postfix -> smtp.strato.de (Brevo im
# hitobito-Mailpfad nicht konfiguriert), CLAUDE.md nennt Versand ueber Brevo-SMTP.
# Vor dem Cutover klaeren; der Filter ist unabhaengig davon richtig.
#
# Entfernt werden zusaetzlich zu X-DSPAM (das der Core selbst entfernt, super):
#   DKIM-Signature, ARC-*, Authentication-Results, Received-SPF,
#   X-MS-*, X-Microsoft-*, X-Forefront-*, X-Exchange-*, X-Originatororg,
#   Thread-Index, Thread-Topic.
# Die Autorisierung (Absenderpruefung, Verteiler-Berechtigung) laeuft ueber
# Envelope/From, nicht ueber diese Header; geaendert wird nur die ausgehende Nachricht.
#
# Fachentscheidung offen "From-Rewriting fuer Verteiler": Der Legacy-Relay behaelt das
# Original-From. Ohne Original-DKIM besteht DMARC nur, wenn der ausgehende Relay mit
# d=<From-Domain> signiert; externe Absender mit p=quarantine/reject koennen abgelehnt
# werden (aktuell DMARC p=none). Siehe docs/wagon-zmv-port.md.
module Kljb::MailRelay::StripAuthHeaders
  STRIPPED_HEADERS = /\A(DKIM-Signature|ARC-|Authentication-Results|Received-SPF|
    X-MS-|X-Microsoft-|X-Forefront-|X-Exchange-|X-Originatororg|Thread-Index|Thread-Topic)/ix

  DSPAM_HEADERS = /\AX-DSPAM/i

  # Entfernt alle passenden Felder (case-insensitiv, auch doppelte Felder).
  # dspam: true entfernt zusaetzlich X-DSPAM-* (im Legacy-Stack macht das der Core).
  def self.strip!(message, dspam: false)
    message.header.fields.delete_if do |field|
      name = field.name.to_s
      name =~ STRIPPED_HEADERS || (dspam && name =~ DSPAM_HEADERS)
    end
    message
  end

  private

  # Erweitert MailRelay::Lists#strip_spam_headers (Core 2.11.5, lists.rb), das im
  # Konstruktor vor super(message) aufgerufen wird. super entfernt X-DSPAM.
  def strip_spam_headers(message)
    super
    Kljb::MailRelay::StripAuthHeaders.strip!(message)
  end
end
