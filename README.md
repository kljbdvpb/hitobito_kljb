# Hitobito Kljb

This hitobito wagon defines the organization hierarchy with groups and roles
of Kljb.


## Organization Hierarchy

• Diözesanverband 
        ▪ Fördermitglied [:passive]
        ▪ IT-Support [:admin, :impersonation, :layer_and_below_full]
    ◦ Diözesanvorstand
        ▪ Seelsorger*in [:layer_and_below_full, :contact_data]
        ▪ Vorstand [:layer_and_below_full, :contact_data]
        ▪ Beratend [:layer_read]
    ◦ Büro
        ▪ Verwaltungsleitung [:layer_and_below_full, :contact_data]
        ▪ Referent*in [:layer_and_below_full, :contact_data]
        ▪ Sekretariat [:layer_and_below_full, :contact_data]
        ▪ Mitarbeiter*in [:layer_and_below_read, :layer_full]
    ◦ AG
        ▪ Sprecher*in [:group_full, :contact_data]
        ▪ Mitglied [:group_read]
    ◦ Kontakte
        ▪ Kontakt [self.visible_from_above = false, :external]
        ▪ Teamer*in [self.visible_from_above = false, :external]
    ◦ Regionalverband
            • Fördermitglied [self.visible_from_above = false; :passive]
        ▪ Vorstand
            • Vorsitz [:layer_and_below_full, :contact_data]
            • Geist [:layer_and_below_full, :contact_data]
            • Finanzverantwortliche*r [:layer_and_below_full, :contact_data]
            • Mitglied [:layer_full, :layer_and_below_read, :contact_data]
        ▪ AG
            • S.o.
        ▪ Kontakte
            • Kontakt [self.visible_from_above = false, :external]
        ▪ Ortsgruppe
                ◦ Fördermitglied [self.visible_from_above = false; :passive]
                ◦ Mitglied [:member]
            • Vorstand
                ◦ S.o.
            • AG
                ◦ S.o.
            • Kontakte
                ◦ Kontakt [self.visible_from_above = false, :external]
            • Leiterrunde
                ◦ Leiter*in [:layer_and_below_read]

(Output of rake app:hitobito:roles)
