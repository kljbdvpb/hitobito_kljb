# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Gleicher Header-Filter fuer den neuen Mail-Stack (Core 2.11.5): Er ist aktiv, sobald
# config/mail.yml existiert (MailConfig.legacy? == false). Dann baut
# Messages::BulkMail::MailFactory die ausgehende Mail aus raw_source und filtert im
# Core keine Header. Details und Hintergrund: Kljb::MailRelay::StripAuthHeaders.
module Kljb::MailRelay::BulkMailStripAuthHeaders
  private

  # MailFactory#initialize ruft set_headers auf, bevor die Mail zugestellt wird.
  def set_headers
    super
    Kljb::MailRelay::StripAuthHeaders.strip!(@mail, dspam: true)
  end
end
