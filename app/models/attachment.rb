class Attachment < ActiveRecord::Base
  require 'rmagick'
  
  belongs_to :entrant_application
  
  def uploaded_file(incoming_file)
    self.filename = incoming_file.original_filename
    self.mime_type = incoming_file.content_type
    md5 = ::Digest::MD5.file(incoming_file.tempfile.path).hexdigest
    self.data_hash = md5
    path = self.data_hash[0..2].split('').join('/')
    %x(mkdir -p #{Rails.root.join('storage', path)})
    file_path = Rails.root.join('storage', path, self.data_hash)
    File.open(file_path, "wb"){|file| file.write(incoming_file.read)}
    if incoming_file.content_type =~ /image/
      self.filename = "#{File.basename(incoming_file.original_filename, '.*')}.jpg"
      self.mime_type = 'image/jpeg'
      img = Magick::Image.read(file_path).first
      img.format = 'JPEG'
      img.scale!(img.columns > img.rows ? 1024 / img.columns.to_f : 1024 / img.rows.to_f) if img.rows > 1024 || img.columns > 1024
      img.write(file_path){ self.quality = 90 }
      %x(jpegoptim -s #{file_path})
    end
  end
end
