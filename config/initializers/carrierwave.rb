# frozen_string_literal: true

# Default CarrierWave setup.
#
CarrierWave.configure do |config|
  config.permissions = 0o666
  config.directory_permissions = 0o777
  config.storage = :file
  config.enable_processing = !Rails.env.test?
end

if Rails.application.secrets.aws_access_key_id.present?
  require "carrierwave/storage/fog"

  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_provider = "fog/aws"
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: Rails.application.secrets.aws_access_key_id,
      aws_secret_access_key: Rails.application.secrets.aws_secret_access_key,
      region: "eu-west-1",
      host: "s3.eu-west-1.amazonaws.com"
      # endpoint:              'https://s3.example.com:8080'
    }
    config.fog_directory = ENV.fetch("AWS_BUCKET_NAME", "decidim-oidp")
    # config.fog_public     = false
    config.fog_attributes = {
      "Cache-Control" => "max-age=#{365.days.to_i}",
      "X-Content-Type-Options" => "nosniff"
    }
  end
end
