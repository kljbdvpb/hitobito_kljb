# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Untergruppen-Export (Mitgliederzaehlung): nur Ortsgruppen. Nutzerentscheidung 2026-11-19:
# Regional-/Dioezesanverbaende, Vorstaende, AGs, Kontakte usw. sind fuer die Auswertung
# unnoetig und wuerden Personen/Zahlen doppelt fuehren. Der Filter sitzt im Job (einziger
# Verwender von Export::Tabular::Groups::List), nicht in der List-Klasse. Geloeschte Gruppen
# filtert weiterhin der Core (without_deleted), Reihenfolge (lft) bleibt erhalten.
module Kljb::Export::SubgroupsExportJob
  EXPORT_GROUP_TYPE = "Group::Ortsgruppe"

  private

  def entries
    super.where(type: EXPORT_GROUP_TYPE)
  end
end
