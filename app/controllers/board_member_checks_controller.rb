# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Bericht "Vorstand/Leitung ohne Mitgliedsrolle" (T75): Personen in Vorstand bzw. Leiterrunde
# einer Ortsgruppe, die in der Ortsgruppe (RV-Vorstand: in einer Ortsgruppe des RV) nicht
# Mitglied sind (moegliche Dubletten oder fehlende Mitgliedschaft). Nur Anzeige, keine
# Aenderung von Daten.
class BoardMemberChecksController < ApplicationController
  helper_method :group, :people

  def index
    # Vorstand/Leiterrunde sind keine Layer-Gruppen: :manage_person_duplicates gilt nur fuer den Layer.
    # Verwaiste Gruppe (Layer fehlt): kein Bericht moeglich, 404 statt NoMethodError/Routing-Fehler
    raise ActiveRecord::RecordNotFound if group.layer_group.nil?

    authorize!(:manage_person_duplicates, group.layer_group)
    raise ActiveRecord::RecordNotFound unless Kljb::BoardMembership.no_new_person?(group)
  end

  private

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people
    @people ||= Kljb::BoardMembership.without_membership(group)
                                     .includes(:roles).order(:last_name, :first_name)
  end
end
