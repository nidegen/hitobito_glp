class Group::Ortsektion < Group

  self.layer = true

  class KommunaleExekutive < Role
  end

  class KommunaleLegislative < Role
  end

  class Schulpflegekommission < Role
  end

  class Rechnungspruefungskommission < Role
  end

  class MitgliedWeitereKommissionen < Role
  end

  roles KommunaleExekutive, KommunaleLegislative, Schulpflegekommission, Rechnungspruefungskommission, MitgliedWeitereKommissionen
  
end
