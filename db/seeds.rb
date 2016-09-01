Campaign.first.entrant_applications.select{|a| a.identity_documents.count > 1}.each{|a| (a.identity_documents - [a.identity_documents.last]).each{|i| i.destroy}}
