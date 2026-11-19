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
  let(:rv_vorstand) { Group::RegionalverbandVorstand.find_by(parent_id: rv.id) }
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
      end.not_to change { [Person.count, Role.count] }

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

  context 'Geistliche Begleitung (Ausnahme von der Sperre)' do
    it 'legt im Ortsgruppen-Vorstand eine neue Person als Geist an, ohne Hinweis' do
      expect do
        post_role(vorstand, Group::OrtsgruppeVorstand::Geist, new_person: new_person)
      end.to change { Person.count }.by(1).and change { Role.count }.by(1)

      expect(flash[:alert]).to be_blank
    end

    it 'legt im RV-Vorstand eine neue Person als Geist an' do
      sign_in(Fabricate(Group::RegionalverbandVorstand::Vorsitz.name.to_sym, group: rv_vorstand).person)

      expect do
        post_role(rv_vorstand, Group::RegionalverbandVorstand::Geist, new_person: new_person)
      end.to change { Person.count }.by(1)
    end

    it 'sperrt weiterhin andere Rollen im selben Vorstand (Rollentyp entscheidet)' do
      expect do
        post_role(vorstand, Group::OrtsgruppeVorstand::Finanzverantwortlicher, new_person: new_person)
      end.not_to change { Person.count }
    end
  end

  context 'RV-Vorstand (keine neue Person)' do
    let(:rv_user) { Fabricate(Group::RegionalverbandVorstand::Vorsitz.name.to_sym, group: rv_vorstand).person }

    before { sign_in(rv_user) }

    it 'lehnt eine neue Person serverseitig ab' do
      expect do
        post_role(rv_vorstand, Group::RegionalverbandVorstand::Mitglied, new_person: new_person)
      end.not_to change { [Person.count, Role.count] }

      expect(assigns(:role).errors[:base].join).to include('zuerst als Mitglied in der Ortsgruppe')
    end

    it 'ordnet eine Person mit Mitgliedsrolle in einer Ortsgruppe des RV ohne Hinweis zu' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
      post_role(rv_vorstand, Group::RegionalverbandVorstand::Mitglied, person_id: person.id)

      expect(Role.where(group_id: rv_vorstand.id, person_id: person.id).count).to eq(1)
      expect(flash[:alert]).to be_blank
    end

    it 'ordnet eine Person ohne Mitgliedsrolle zu, mit Hinweis' do
      post_role(rv_vorstand, Group::RegionalverbandVorstand::Mitglied, person_id: person.id)

      expect(Role.where(group_id: rv_vorstand.id, person_id: person.id).count).to eq(1)
      expect(flash[:alert]).to include(person.to_s)
    end

    it 'gibt fuer die Geistliche Begleitung keinen Hinweis' do
      post_role(rv_vorstand, Group::RegionalverbandVorstand::Geist, person_id: person.id)
      expect(flash[:alert]).to be_blank
    end
  end

  context 'normale Gruppen bleiben unveraendert' do
    it 'legt in der Ortsgruppen-AG eine neue Person an (ungesperrt)' do
      ag = Group::OrtsgruppeAg.find_by(parent_id: og.id) || Fabricate(Group::OrtsgruppeAg.name.to_sym, parent: og)
      expect do
        post_role(ag, Group::OrtsgruppeAg::Mitglied, new_person: new_person)
      end.to change { Person.count }.by(1)
    end

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

    # Das Layout bindet application.css ein; Assets sind in der Wagon-CI nicht gebaut
    # (Propshaft::MissingAssetError). Fuer die Formular-Pruefung genuegt das Template.
    before { allow(controller).to receive(:_layout).and_return(nil) }

    it 'zeigt im Vorstand nur die Suche, keinen Umschalter auf neue Person' do
      get :new, params: { group_id: vorstand.id, role: { type: Group::OrtsgruppeVorstand::Mitglied.sti_name } }

      expect(response.body).to include('Bestehende Person suchen')
      expect(response.body).not_to include('Neue Person erfassen')
      expect(response.body).not_to include('role_new_person_first_name')
    end

    it 'zeigt im Vorstand mit Rollentyp Mitglied nur die Suche samt Link auf Geist-Formular' do
      get :new, params: { group_id: vorstand.id, role: { type: Group::OrtsgruppeVorstand::Mitglied.sti_name } }

      expect(response.body).to include('Geistliche Begleitung neu erfassen')
      expect(response.body).to include(CGI.escapeHTML(
        new_group_role_path(vorstand, role: { type: Group::OrtsgruppeVorstand::Geist.sti_name })
      ))
    end

    it 'bietet bei vorgewaehltem Rollentyp Geist beide Varianten an' do
      get :new, params: { group_id: vorstand.id, role: { type: Group::OrtsgruppeVorstand::Geist.sti_name } }

      expect(response.body).to include('Neue Person erfassen')
      expect(response.body).to include('Bestehende Person suchen')
    end

    it 'zeigt im RV-Vorstand nur die Suche' do
      sign_in(Fabricate(Group::RegionalverbandVorstand::Vorsitz.name.to_sym, group: rv_vorstand).person)
      get :new, params: { group_id: rv_vorstand.id, role: { type: Group::RegionalverbandVorstand::Mitglied.sti_name } }

      expect(response.body).not_to include('Neue Person erfassen')
    end

    it 'zeigt in der Ortsgruppe weiterhin beide Varianten' do
      get :new, params: { group_id: og.id, role: { type: Group::Ortsgruppe::Mitglied.sti_name } }

      expect(response.body).to include('Neue Person erfassen')
      expect(response.body).to include('Bestehende Person suchen')
    end
  end
end
