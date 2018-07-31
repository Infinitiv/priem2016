class Report
  def self.mon(campaign)
    points = {}
    campaign.admission_volumes.each do |admission_volume|
      direction_id = admission_volume.direction_id
      points[direction_id] = {}
      points[direction_id][:f1_2] = {}
      points[direction_id][:f2_2] = {}
      points[direction_id][:f2_3] = {}
      
      competitive_groups = campaign.competitive_groups.where(direction_id: direction_id, education_source_id: 14)
      entrant_applications = campaign.entrant_applications.joins(:competitive_groups).where(competitive_groups: {id: competitive_groups.map(&:id)})
      entrant_applications_examless = entrant_applications.joins(:olympic_documents).where(olympic_documents: {benefit_type_id: 1})
      points[direction_id][:f1_2][:p12_2] = entrant_applications_examless.count
      
      competitive_groups = campaign.competitive_groups.where(direction_id: direction_id, education_source_id: 20)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id))
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: campaign.entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_10] = mean
      
      competitive_groups = campaign.competitive_groups.where(direction_id: direction_id, education_source_id: 16)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id))
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_11] = mean
      
      competitive_groups = CompetitiveGroup.where(direction_id: direction_id, education_source_id: 14)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id), olympionic: false)
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_12] = mean
      
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id))
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_13] = mean
      
      competitive_groups = CompetitiveGroup.where(direction_id: direction_id, education_source_id: 15)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id), olympionic: false)
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_12p] = mean
      
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id))
      marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}, form: 'ЕГЭ')
      mean = (marks.sum(:value).to_f/marks.count).round(2)
      points[direction_id][:f2_2][:p2_13p] = mean
      
      competitive_groups = CompetitiveGroup.where(direction_id: direction_id).where.not(education_source_id: 15)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id)).joins(:institution_achievements).where(institution_achievements: {id_category: [9, 15, 16]})
      points[direction_id][:f2_3][:p2_30] = entrant_applications.count
            
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id)).joins(:institution_achievements).where(institution_achievements: {id_category: 17})
      points[direction_id][:f2_3][:p2_31] = entrant_applications.count
      
      competitive_groups = CompetitiveGroup.where(direction_id: direction_id, education_source_id: 15)
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id)).joins(:institution_achievements).where(institution_achievements: {id_category: [9, 15, 16]})
      points[direction_id][:f2_3][:p2_30p] = entrant_applications.count
      
      entrant_applications = campaign.entrant_applications.where(enrolled: competitive_groups.map(&:id)).joins(:institution_achievements).where(institution_achievements: {id_category: 17})
      points[direction_id][:f2_3][:p2_31p] = entrant_applications.count
    end
    points
  end
end
