# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module HitobitoKljb
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement '>= 2.11'

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    config.to_prepare do
      JobManager.wagon_jobs += [MemberPaymentStatusJob]

      # extend application classes here
      Group.include Kljb::Group
      Person.include Kljb::Person
      Event.include Kljb::Event

      Event::ParticipationContactData.include Kljb::Event::ParticipationContactData

      # Quicksearch (/full.json): Gruppen vor Personen
      FullTextController.prepend Kljb::QuicksearchGroupsFirst

      # Anlaesse und Kurse ausblenden (Daten bleiben, siehe app/domain/kljb/hide_events)
      Kljb::HideEvents.apply_main_nav!
      PersonDecorator.prepend Kljb::HideEvents::PersonDecorator

      # Dubletten-Vorbeugung (T75): keine neue Person in Vorstand/Leiterrunde der Ortsgruppe
      # (Formular, Server-Sperre, CSV-Import), siehe app/domain/kljb/board_membership.rb
      ::RolesController.prepend Kljb::BoardMembership::RolesController
      ::RolesHelper.prepend Kljb::BoardMembership::RolesHelper
      Import::PersonImporter.prepend Kljb::BoardMembership::PersonImporter

      Export::Tabular::Groups::List.prepend Kljb::Export::Tabular::Groups::List
      Export::Tabular::People::PeopleAddress.prepend Kljb::Export::Tabular::People::HideNickname
      Export::Tabular::People::PeopleFull.prepend Kljb::Export::Tabular::People::HideNickname

      # Authentifizierungs-Header vor dem Verteiler-Relay entfernen (web.de/GMX)
      # Legacy-Stack (ohne config/mail.yml) und neuer Stack (mit config/mail.yml)
      MailRelay::Lists.prepend Kljb::MailRelay::StripAuthHeaders
      Messages::BulkMail::MailFactory.prepend Kljb::MailRelay::BulkMailStripAuthHeaders

      # Spitzname auch in vCard, API (Legacy-REST, JSON:API), Etiketten, Listenkoepfen und
      # Event-Kontaktattributen ausblenden (siehe app/domain/kljb/hide_nickname)
      Export::Vcf::Vcards.prepend Kljb::Export::Vcf::HideNickname
      ApplicationSerializer.prepend Kljb::HideNickname::Serializer
      Kljb::HideNickname::JsonApi.apply!
      OidcClaimSetup.prepend Kljb::HideNickname::OidcClaims
      Contactable::Address.prepend Kljb::HideNickname::Address
      PeopleHelper.prepend Kljb::HideNickname::PeopleHelper
      Event::ParticipationContactData.prepend Kljb::HideNickname::RequiredAttrs
      Wizards::RegisterNewEventGuestWizard.prepend Kljb::HideNickname::RequiredAttrs
    end

    initializer "kljb.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!
    end

    initializer "kljb.add_inflections" do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        # inflect.irregular 'census', 'censuses'
      end
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end
  end
end
