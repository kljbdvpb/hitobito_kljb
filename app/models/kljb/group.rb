# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb::Group
  extend ActiveSupport::Concern

  included do
    # Define additional used attributes
    # self.used_attributes += [:website, :bank_account, :description]
    # self.superior_attributes = [:bank_account]

    root_types Group::Dioezesanverband

    # Anlaesse und Kurse sind in der KLJB-Instanz abgeschaltet (Nutzerentscheidung
    # 2026-11-19, docs/webtest-befunde-3.md). Ohne Event-Typen blendet der Core den
    # Gruppen-Reiter Anlaesse/Kurse aus (Sheet::Group), Group.course_types ist leer
    # (Menue Kurse, Kursarten, Qualifikationsarten) und niemand darf Qualifikationen
    # anlegen (QualificationAbility). Bestehende Daten bleiben in der DB.
    # Gilt fuer alle Gruppentypen (Vererbung per class_attribute), keine Typ-Override noetig.
    self.event_types = []
  end
end
