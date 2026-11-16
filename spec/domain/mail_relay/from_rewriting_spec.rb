# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Absicherung (Fachentscheidung D4, Option A): Der Core (2.11.5, neuer Mail-Stack mit
# config/mail.yml) schreibt From auf "<Name> via <Verteileradresse>" <Verteileradresse> um und
# setzt Reply-To auf den Originalabsender. Der Wagon ergaenzt dafuer keinen Code; diese Spec
# faellt auf, falls ein Core-Update das Verhalten aendert oder der Wagon-Header-Filter es stoert.
describe "From-Rewriting im Verteiler-Relay (Core-Verhalten)" do
  let(:mailing_list) { double("MailingList", mail_address: "liste@post.example.com") }
  let(:raw_mail) do
    <<~MAIL.gsub("\n", "\r\n")
      Return-Path: <anna@gmail.example>
      From: "Anna \\"Ann\\" Muster" <anna@gmail.example>
      To: liste@post.example.com
      Subject: Test
      DKIM-Signature: v=1; a=rsa-sha256; d=gmail.example; s=sel; b=abc
      Message-ID: <abc@gmail.example>

      Hallo
    MAIL
  end
  let(:bulk_mail_message) do
    double("Message", raw_source: raw_mail, uid: "abc123", mailing_list: mailing_list)
  end
  let(:mail) do
    Messages::BulkMail::MailFactory.new(bulk_mail_message).instance_variable_get(:@mail)
  end

  it "setzt From auf Verteileradresse (DKIM-Domain des Verteilers) mit Namen des Absenders" do
    expect(mail.from).to eq ["liste@post.example.com"]
    expect(mail.header["From"].display_names.first).to eq 'Anna "Ann" Muster via liste@post.example.com'
  end

  it "setzt Reply-To auf den Originalabsender" do
    expect(mail.reply_to).to eq ["anna@gmail.example"]
  end

  it "setzt den Envelope-Sender (Bounces) auf die Verteileradresse" do
    expect(mail.smtp_envelope_from).to eq "liste@post.example.com"
  end

  it "enthaelt keine zusaetzlichen From-/Reply-To-Zeilen (kein Header-Injection-Rest)" do
    expect(mail.header.fields.count { |f| f.name.casecmp?("From") }).to eq 1
    expect(mail.header.fields.count { |f| f.name.casecmp?("Reply-To") }).to eq 1
  end

  it "entfernt die Original-DKIM-Signatur (Wagon-Filter)" do
    expect(mail.header.fields.map(&:name).grep(/\Adkim-signature\z/i)).to be_empty
  end
end
