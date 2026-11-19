# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe RolesController, type: :controller do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:leiterrunde) { Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id) }
  let(:kontakte) { Group::OrtsgruppeKontakte.find_by(parent_id: og.id) }
  let(:user) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }

  let(:person) { Fabricate(:person) }
  let(:new_person) { { first_name: 'Neu', last_name: 'Person', email: 'neu.person@example.com' } }

  before { sign_in(user) }

  def post_role(group, type, extra)
    post :create, params: { group_id: group.id, role: { group_id: group.id, type: type.sti_name }.merge(extra) }
  end

  context 'Vorstand (keine neue Person)' do
    it 'lehnt eine neue Person serverseitig ab, legt weder Person noch Rolle an' do
      expect do
        post_role(vorstand, Group::OrtsgruppeVorstand::Mitglied, new_person: new_person)
      end.to change { [Person.count, Role.count] }.by([0, 0])

      expect(response).not_to be_redirect
      expect(assigns(:role).errors[:base].join).to include('zuerst als Mitglied in der Ortsgruppe')
      expect(Person.find_by(email: 'neu.person@example.com')).to be_nil
    end

    it 'lehnt eine neue Person auch in der Leiterrunde ab' do
      expect do
        post_role(leiterrunde, Group::OrtsgruppeLeiterrunde::Leiter, new_person: new_person)
      end.not_to change { Person.count }
    end

    it 'ordnet eine bestehende Person mit Mitgliedsrolle zu, ohne Hinweis' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)

      expect do
        post_role(vorstand, Group::OrtsgruppeVorstand::Mitglied, person_id: person.id)
      end.to change { Role.where(group_id: vorstand.id, person_id: person.id).count }.by(1)

      expect(flash[:alert]).to be_blank
    end

    it 'ordnet eine bestehende Person ohne Mitgliedsrolle zu, mit Hinweis (kein Fehler)' do
      expect do
        post_role(vorstand, Group::OrtsgruppeVorstand::Mitglied, person_id: person.id)
      end.to change { Role.where(group_id: vorstand.id, person_id: person.id).count }.by(1)

      expect(flash[:alert]).to include(person.to_s)
    end

    it 'gibt fuer die Geistliche Leitung keinen Hinweis' do
      post_role(vorstand, Group::OrtsgruppeVorstand::Geist, person_id: person.id)
      expect(flash[:alert]).to be_blank
    end
  end

  context 'normale Gruppen bleiben unveraendert' do
    it 'legt in der Ortsgruppe eine neue Person als Mitglied an' do
      expect do
        post_role(og, Group::Ortsgruppe::Mitglied, new_person: new_person)
      end.to change { Person.count }.by(1).and change { Role.count }.by(1)
    end

    it 'legt in den Kontakten eine neue Person an' do
      expect do
        post_role(kontakte, Group::OrtsgruppeKontakte::Kontakt, new_person: new_person)
      end.to change { Person.count }.by(1)
    end
  end

  context 'Formular' do
    render_views

    it 'zeigt im Vorstand nur die Suche, keinen Umschalter auf neue Person' do
      get :new, params: { group_id: vorstand.id, role: { type: Group::OrtsgruppeVorstand::Mitglied.sti_name } }

      expect(response.body).to include('Bestehende Person suchen')
      expect(response.body).not_to include('Neue Person erfassen')
      expect(response.body).not_to include('role_new_person_first_name')
    end

    it 'zeigt in der Ortsgruppe weiterhin beide Varianten' do
      get :new, params: { group_id: og.id, role: { type: Group::Ortsgruppe::Mitglied.sti_name } }

      expect(response.body).to include('Neue Person erfassen')
      expect(response.body).to include('Bestehende Person suchen')
    end
  end
end
