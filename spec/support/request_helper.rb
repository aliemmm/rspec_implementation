module RequestHelper
  using DeepFetch

  # Gives you whole parsed JSON body of a response or a part you're interested in.
  # @param path [Array<String, Number>] a path you wanna +dig+ into
  # @raise [KeyError] if unable to find data by provided key in path
  # @return [Object, nil]
  def json_body(*path)
    body = response.parsed_body
    return body if path.blank?

    body.deep_fetch(*path)
  end
  alias_method :json, :json_body

  def uploaded_invalid_image
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/files/invalid_image.jpg").to_s,
      "image/jpeg"
    )
  end

  def travel_to_record_time(cassette)
    return if cassette.recording?

    travel_to(cassette.originally_recorded_at)
  end
end
