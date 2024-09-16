module UploadedFileHelper
  def uploaded_file(name)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/support/files/#{name}").to_s)
  end
end
