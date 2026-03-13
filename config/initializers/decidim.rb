# frozen_string_literal: true

Decidim.configure do |config|
  # The name of the application
  config.application_name = Decidim::Env.new("DECIDIM_APPLICATION_NAME").to_json

  # The email that will be used as sender in all emails from Decidim
  config.mailer_sender = Decidim::Env.new("DECIDIM_MAILER_SENDER").to_s

  # Sets the list of available locales for the whole application.
  #
  # When an organization is created through the System area, system admins will
  # be able to choose the available languages for that organization. That list
  # of languages will be equal or a subset of the list in this file.
  config.available_locales = Decidim::Env.new("DECIDIM_AVAILABLE_LOCALES").to_array.presence || [:en]

  # Sets the default locale for new organizations. When creating a new
  # organization from the System area, system admins will be able to overwrite
  # this value for that specific organization.
  config.default_locale = Decidim::Env.new("DECIDIM_DEFAULT_LOCALE").to_s.presence || :en

  # Restrict access to the system part with an authorized ip list.
  # You can use a single ip like ("1.2.3.4"), or an ip subnet like ("1.2.3.4/24")
  # You may specify multiple ip in an array ["1.2.3.4", "1.2.3.4/24"]
  system_accesslist_ips = Decidim::Env.new("DECIDIM_SYSTEM_ACCESSLIST_IPS").to_array
  config.system_accesslist_ips = system_accesslist_ips if system_accesslist_ips.present?

  # Whether SSL should be enabled or not.
  # if this var is not defined, it is decided automatically per-rails-environment
  force_ssl = Decidim::Env.new("DECIDIM_FORCE_SSL", "auto").default_or_present_if_exists.to_s
  config.force_ssl = force_ssl.present? unless force_ssl == "auto"

  # Enable the service worker. By default is disabled in development and enabled in the rest of environments
  config.service_worker_enabled = Decidim::Env.new("DECIDIM_SERVICE_WORKER_ENABLED").present?

  # Storage provider and CDN host (new in 0.31)
  config.storage_provider = Decidim::Env.new("STORAGE_PROVIDER").to_s if Decidim::Env.new("STORAGE_PROVIDER").present?
  config.storage_cdn_host = Decidim::Env.new("STORAGE_CDN_HOST").to_s if Decidim::Env.new("STORAGE_CDN_HOST").present?

  # Map and Geocoder configuration
  #
  # == HERE Maps ==
  config.maps = {
    provider: :here,
    api_key: Decidim::Env.new("MAPS_API_KEY").to_s,
    static: { url: "https://image.maps.ls.hereapi.com/mia/1.6/mapview" }
  }
  #
  # == OpenStreetMap (OSM) services ==
  # To use the OSM map service providers, you will need a service provider for
  # the following map servers or host all of them yourself:
  # - A tile server for the dynamic maps
  #   (https://wiki.openstreetmap.org/wiki/Tile_servers)
  # - A Nominatim geocoding server for the geocoding functionality
  #   (https://wiki.openstreetmap.org/wiki/Nominatim)
  # - A static map server for static map images
  #   (https://github.com/jperelli/osm-static-maps)
  #
  # When used, please read carefully the terms of service for your service
  # provider.
  #
  # config.maps = {
  #   provider: :osm,
  #   api_key: Decidim::Env.new("MAPS_API_KEY").to_s,
  #   dynamic: {
  #     tile_layer: {
  #       url: "https://tiles.example.org/{z}/{x}/{y}.png?key={apiKey}&{foo}",
  #       api_key: true,
  #       foo: "bar=baz",
  #       attribution: %(
  #         <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap</a> contributors
  #       ).strip
  #       # Translatable attribution:
  #       # attribution: -> { I18n.t("tile_layer_attribution") }
  #     }
  #   },
  #   static: { url: "https://staticmap.example.org/" },
  #   geocoding: { host: "nominatim.example.org", use_https: true }
  # }
  #
  # == Combination (OpenStreetMap default + HERE Maps dynamic map tiles) ==
  # config.maps = {
  #   provider: :osm,
  #   api_key: Decidim::Env.new("MAPS_API_KEY").to_s,
  #   dynamic: {
  #     provider: :here,
  #     api_key: Decidim::Env.new("MAPS_HERE_API_KEY").to_s
  #   },
  #   static: { url: "https://staticmap.example.org/" },
  #   geocoding: { host: "nominatim.example.org", use_https: true }
  # }

  # Geocoder configurations if you want to customize the default geocoding
  # settings. The maps configuration will manage which geocoding service to use,
  # so that does not need any additional configuration here. Use this only for
  # the global geocoder preferences.
  config.geocoder = {
    # geocoding service request timeout, in seconds (default 3):
    timeout: 5,
    # set default units to kilometers:
    units: :km
    # caching (see https://github.com/alexreisner/geocoder#caching for details):
    # cache: Redis.new,
    # cache_prefix: "..."
  }

  # Custom maps configuration from environment variables
  if Decidim::Env.new("MAPS_STATIC_PROVIDER").present?
    static_provider = Decidim::Env.new("MAPS_STATIC_PROVIDER").to_s
    dynamic_provider = Decidim::Env.new("MAPS_DYNAMIC_PROVIDER").to_s
    dynamic_url = Decidim::Env.new("MAPS_DYNAMIC_URL").to_s
    static_url = Decidim::Env.new("MAPS_STATIC_URL").to_s
    static_url = "https://image.maps.ls.hereapi.com/mia/1.6/mapview" if static_provider == "here" && static_url.blank?
    config.maps = {
      provider: static_provider,
      api_key: Decidim::Env.new("MAPS_STATIC_API_KEY").to_s,
      static: { url: static_url },
      dynamic: {
        provider: dynamic_provider,
        api_key: Decidim::Env.new("MAPS_DYNAMIC_API_KEY").to_s
      }
    }
    geocoding_host = Decidim::Env.new("MAPS_GEOCODING_HOST").to_s
    config.maps[:geocoding] = { host: geocoding_host, use_https: true } if geocoding_host.present?
    config.maps[:dynamic][:tile_layer] = {}
    config.maps[:dynamic][:tile_layer][:url] = dynamic_url if dynamic_url.present?
    attribution = Decidim::Env.new("MAPS_ATTRIBUTION").to_s
    config.maps[:dynamic][:tile_layer][:attribution] = attribution if attribution.present?
    extra_vars = Decidim::Env.new("MAPS_EXTRA_VARS").to_s
    if extra_vars.present?
      vars = URI.decode_www_form(extra_vars)
      vars.each do |key, value|
        # perform a naive type conversion
        config.maps[:dynamic][:tile_layer][key] = case value
                                                  when /^true$|^false$/i
                                                    value.downcase == "true"
                                                  when /\A[-+]?\d+\z/
                                                    value.to_i
                                                  else
                                                    value
                                                  end
      end
    end
  end

  # Currency unit
  config.currency_unit = Decidim::Env.new("DECIDIM_CURRENCY_UNIT").to_s if Decidim::Env.new("DECIDIM_CURRENCY_UNIT").present?

  # Workaround to enable SVG assets cors
  config.cors_enabled = Decidim::Env.new("DECIDIM_CORS_ENABLED").present?

  # Defines the quality of image uploads after processing. Image uploads are
  # processed by Decidim, this value helps reduce the size of the files.
  config.image_uploader_quality = Decidim::Env.new("DECIDIM_IMAGE_UPLOADER_QUALITY").to_i if Decidim::Env.new("DECIDIM_IMAGE_UPLOADER_QUALITY").present?

  config.maximum_attachment_size = Decidim::Env.new("DECIDIM_MAXIMUM_ATTACHMENT_SIZE").to_i.megabytes if Decidim::Env.new("DECIDIM_MAXIMUM_ATTACHMENT_SIZE").present?
  config.maximum_avatar_size = Decidim::Env.new("DECIDIM_MAXIMUM_AVATAR_SIZE").to_i.megabytes if Decidim::Env.new("DECIDIM_MAXIMUM_AVATAR_SIZE").present?

  # The number of reports which a resource can receive before hiding it
  config.max_reports_before_hiding = Decidim::Env.new("DECIDIM_MAX_REPORTS_BEFORE_HIDING").to_i if Decidim::Env.new("DECIDIM_MAX_REPORTS_BEFORE_HIDING").present?

  # Custom HTML Header snippets
  #
  # The most common use is to integrate third-party services that require some
  # extra JavaScript or CSS. Also, you can use it to add extra meta tags to the
  # HTML. Note that this will only be rendered in public pages, not in the admin
  # section.
  #
  # Before enabling this you should ensure that any tracking that might be done
  # is in accordance with the rules and regulations that apply to your
  # environment and usage scenarios. This component also comes with the risk
  # that an organization's administrator injects malicious scripts to spy on or
  # take over user accounts.
  #
  config.enable_html_header_snippets = Decidim::Env.new("DECIDIM_ENABLE_HTML_HEADER_SNIPPETS").present?

  # Allow organizations admins to track newsletter links.
  track_newsletter_links = Decidim::Env.new("DECIDIM_TRACK_NEWSLETTER_LINKS", "auto").default_or_present_if_exists.to_s
  config.track_newsletter_links = track_newsletter_links.present? unless track_newsletter_links == "auto"

  # Amount of time that the download your data files will be available in the server.
  if Decidim::Env.new("DECIDIM_DOWNLOAD_YOUR_DATA_EXPIRY_TIME").present?
    config.download_your_data_expiry_time = Decidim::Env.new("DECIDIM_DOWNLOAD_YOUR_DATA_EXPIRY_TIME").to_i.days
  end

  # Max requests in a time period to prevent DoS attacks. Only applied on production.
  config.throttling_max_requests = Decidim::Env.new("DECIDIM_THROTTLING_MAX_REQUESTS").to_i if Decidim::Env.new("DECIDIM_THROTTLING_MAX_REQUESTS").present?

  # Time window in which the throttling is applied.
  config.throttling_period = Decidim::Env.new("DECIDIM_THROTTLING_PERIOD").to_i.minutes if Decidim::Env.new("DECIDIM_THROTTLING_PERIOD").present?

  # Time window were users can access the website even if their email is not confirmed.
  config.unconfirmed_access_for = Decidim::Env.new("DECIDIM_UNCONFIRMED_ACCESS_FOR").to_i.days if Decidim::Env.new("DECIDIM_UNCONFIRMED_ACCESS_FOR").present?

  # A base path for the uploads. If set, make sure it ends in a slash.
  # Uploads will be set to `<base_path>/uploads/`. This can be useful if you
  # want to use the same uploads place for both staging and production
  # environments, but in different folders.
  #
  # If not set, it will be ignored.
  base_uploads_path = Decidim::Env.new("DECIDIM_BASE_UPLOADS_PATH").to_s
  config.base_uploads_path = base_uploads_path if base_uploads_path.present?

  # SMS gateway configuration
  #
  # If you want to verify your users by sending a verification code via
  # SMS you need to provide a SMS gateway service class.
  #
  # An example class would be something like:
  #
  # class MySMSGatewayService
  #   attr_reader :mobile_phone_number, :code
  #
  #   def initialize(mobile_phone_number, code)
  #     @mobile_phone_number = mobile_phone_number
  #     @code = code
  #   end
  #
  #   def deliver_code
  #     # Actual code to deliver the code
  #     true
  #   end
  # end
  #
  # config.sms_gateway_service = "MySMSGatewayService"

  # Timestamp service configuration
  #
  # Provide a class to generate a timestamp for a document. The instances of
  # this class are initialized with a hash containing the :document key with
  # the document to be timestamped as value. The istances respond to a
  # timestamp public method with the timestamp
  #
  # An example class would be something like:
  #
  # class MyTimestampService
  #   attr_accessor :document
  #
  #   def initialize(args = {})
  #     @document = args.fetch(:document)
  #   end
  #
  #   def timestamp
  #     # Code to generate timestamp
  #     "My timestamp"
  #   end
  # end
  #
  #
  # config.timestamp_service = "MyTimestampService"

  # PDF signature service configuration
  #
  # Provide a class to process a pdf and return the document including a
  # digital signature. The instances of this class are initialized with a hash
  # containing the :pdf key with the pdf file content as value. The instances
  # respond to a signed_pdf method containing the pdf with the signature
  #
  # An example class would be something like:
  #
  # class MyPDFSignatureService
  #   attr_accessor :pdf
  #
  #   def initialize(args = {})
  #     @pdf = args.fetch(:pdf)
  #   end
  #
  #   def signed_pdf
  #     # Code to return the pdf signed
  #   end
  # end
  #
  # config.pdf_signature_service = "MyPDFSignatureService"

  # Etherpad configuration
  #
  # Only needed if you want to have Etherpad integration with Decidim. See
  # Decidim docs at https://docs.decidim.org/en/services/etherpad/ in order to set it up.
  #
  if Decidim::Env.new("ETHERPAD_SERVER").present?
    config.etherpad = {
      server: Decidim::Env.new("ETHERPAD_SERVER").to_s,
      api_key: Decidim::Env.new("ETHERPAD_API_KEY").to_s,
      api_version: Decidim::Env.new("ETHERPAD_API_VERSION").to_s
    }
  end

  # Sets Decidim::Exporters::CSV's default column separator
  config.default_csv_col_sep = Decidim::Env.new("DECIDIM_DEFAULT_CSV_COL_SEP").to_s if Decidim::Env.new("DECIDIM_DEFAULT_CSV_COL_SEP").present?

  # Machine Translation Configuration
  #
  # See Decidim docs at https://docs.decidim.org/en/develop/machine_translations/
  # for more information about how it works and how to set it up.
  #
  # Enable machine translations
  config.enable_machine_translations = false

  # Defines the name of the cookie used to check if the user allows Decidim to
  # set cookies.
  config.consent_cookie_name = Decidim::Env.new("DECIDIM_CONSENT_COOKIE_NAME").to_s if Decidim::Env.new("DECIDIM_CONSENT_COOKIE_NAME").present?

  # Admin password configurations
  config.admin_password_strong = Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_STRONG").present? if Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_STRONG").present?
  config.admin_password_expiration_days = Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_EXPIRATION_DAYS").to_i if Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_EXPIRATION_DAYS").present?
  config.admin_password_min_length = Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_MIN_LENGTH").to_i if Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_MIN_LENGTH").present?
  config.admin_password_repetition_times = Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_REPETITION_TIMES").to_i if Decidim::Env.new("DECIDIM_ADMIN_PASSWORD_REPETITION_TIMES").present?

  # Additional optional configurations (see decidim-core/lib/decidim/core.rb)
  config.cache_key_separator = Decidim::Env.new("DECIDIM_CACHE_KEY_SEPARATOR").to_s if Decidim::Env.new("DECIDIM_CACHE_KEY_SEPARATOR").present?
  config.expire_session_after = Decidim::Env.new("DECIDIM_EXPIRE_SESSION_AFTER").to_i.minutes if Decidim::Env.new("DECIDIM_EXPIRE_SESSION_AFTER").present?
  enable_remember_me = Decidim::Env.new("DECIDIM_ENABLE_REMEMBER_ME", "auto").default_or_present_if_exists.to_s
  config.enable_remember_me = enable_remember_me.present? unless enable_remember_me == "auto"
  config.session_timeout_interval = Decidim::Env.new("DECIDIM_SESSION_TIMEOUT_INTERVAL").to_i.seconds if Decidim::Env.new("DECIDIM_SESSION_TIMEOUT_INTERVAL").present?
  config.follow_http_x_forwarded_host = Decidim::Env.new("DECIDIM_FOLLOW_HTTP_X_FORWARDED_HOST").present?
  if Decidim::Env.new("DECIDIM_MAXIMUM_CONVERSATION_MESSAGE_LENGTH").present?
    config.maximum_conversation_message_length = Decidim::Env.new("DECIDIM_MAXIMUM_CONVERSATION_MESSAGE_LENGTH").to_i
  end
  denied_passwords = Decidim::Env.new("DECIDIM_PASSWORD_BLACKLIST").to_array(separator: ", ")
  config.denied_passwords = denied_passwords if denied_passwords.present?
  config.allow_open_redirects = Decidim::Env.new("DECIDIM_ALLOW_OPEN_REDIRECTS").present?
end

if Decidim.module_installed? :api
  Decidim::Api.configure do |config|
    config.schema_max_per_page = Decidim::Env.new("API_SCHEMA_MAX_PER_PAGE").to_i if Decidim::Env.new("API_SCHEMA_MAX_PER_PAGE").present?
    config.schema_max_complexity = Decidim::Env.new("API_SCHEMA_MAX_COMPLEXITY").to_i if Decidim::Env.new("API_SCHEMA_MAX_COMPLEXITY").present?
    config.schema_max_depth = Decidim::Env.new("API_SCHEMA_MAX_DEPTH").to_i if Decidim::Env.new("API_SCHEMA_MAX_DEPTH").present?
  end
end

if Decidim.module_installed? :proposals
  Decidim::Proposals.configure do |config|
    config.similarity_threshold = Decidim::Env.new("PROPOSALS_SIMILARITY_THRESHOLD").to_f if Decidim::Env.new("PROPOSALS_SIMILARITY_THRESHOLD").present?
    config.similarity_limit = Decidim::Env.new("PROPOSALS_SIMILARITY_LIMIT").to_i if Decidim::Env.new("PROPOSALS_SIMILARITY_LIMIT").present?
    if Decidim::Env.new("PROPOSALS_PARTICIPATORY_SPACE_HIGHLIGHTED_PROPOSALS_LIMIT").present?
      config.participatory_space_highlighted_proposals_limit = Decidim::Env.new("PROPOSALS_PARTICIPATORY_SPACE_HIGHLIGHTED_PROPOSALS_LIMIT").to_i
    end
    if Decidim::Env.new("PROPOSALS_PROCESS_GROUP_HIGHLIGHTED_PROPOSALS_LIMIT").present?
      config.process_group_highlighted_proposals_limit = Decidim::Env.new("PROPOSALS_PROCESS_GROUP_HIGHLIGHTED_PROPOSALS_LIMIT").to_i
    end
  end
end

if Decidim.module_installed? :meetings
  Decidim::Meetings.configure do |config|
    if Decidim::Env.new("MEETINGS_UPCOMING_MEETING_NOTIFICATION").present?
      config.upcoming_meeting_notification = Decidim::Env.new("MEETINGS_UPCOMING_MEETING_NOTIFICATION").to_i.days
    end
    embeddable_services = Decidim::Env.new("MEETINGS_EMBEDDABLE_SERVICES").to_array(separator: " ")
    config.embeddable_services = embeddable_services if embeddable_services.present?
    enable_proposal_linking = Decidim::Env.new("MEETINGS_ENABLE_PROPOSAL_LINKING", "auto").default_or_present_if_exists.to_s
    config.enable_proposal_linking = enable_proposal_linking.present? unless enable_proposal_linking == "auto"
  end
end

if Decidim.module_installed? :budgets
  Decidim::Budgets.configure do |config|
    enable_proposal_linking = Decidim::Env.new("BUDGETS_ENABLE_PROPOSAL_LINKING", "auto").default_or_present_if_exists.to_s
    config.enable_proposal_linking = enable_proposal_linking.present? unless enable_proposal_linking == "auto"
  end
end

if Decidim.module_installed? :initiatives
  Decidim::Initiatives.configure do |config|
    creation_enabled = Decidim::Env.new("INITIATIVES_CREATION_ENABLED", "auto").default_or_present_if_exists.to_s
    config.creation_enabled = creation_enabled.present? unless creation_enabled == "auto"
    config.similarity_threshold = Decidim::Env.new("INITIATIVES_SIMILARITY_THRESHOLD").to_f if Decidim::Env.new("INITIATIVES_SIMILARITY_THRESHOLD").present?
    config.similarity_limit = Decidim::Env.new("INITIATIVES_SIMILARITY_LIMIT").to_i if Decidim::Env.new("INITIATIVES_SIMILARITY_LIMIT").present?
    config.minimum_committee_members = Decidim::Env.new("INITIATIVES_MINIMUM_COMMITTEE_MEMBERS").to_i if Decidim::Env.new("INITIATIVES_MINIMUM_COMMITTEE_MEMBERS").present?
    if Decidim::Env.new("INITIATIVES_DEFAULT_SIGNATURE_TIME_PERIOD_LENGTH").present?
      config.default_signature_time_period_length = Decidim::Env.new("INITIATIVES_DEFAULT_SIGNATURE_TIME_PERIOD_LENGTH").to_i
    end
    config.default_components = Decidim::Env.new("INITIATIVES_DEFAULT_COMPONENTS").to_array if Decidim::Env.new("INITIATIVES_DEFAULT_COMPONENTS").present?
    if Decidim::Env.new("INITIATIVES_FIRST_NOTIFICATION_PERCENTAGE").present?
      config.first_notification_percentage = Decidim::Env.new("INITIATIVES_FIRST_NOTIFICATION_PERCENTAGE").to_i
    end
    if Decidim::Env.new("INITIATIVES_SECOND_NOTIFICATION_PERCENTAGE").present?
      config.second_notification_percentage = Decidim::Env.new("INITIATIVES_SECOND_NOTIFICATION_PERCENTAGE").to_i
    end
    if Decidim::Env.new("INITIATIVES_STATS_CACHE_EXPIRATION_TIME").present?
      config.stats_cache_expiration_time = Decidim::Env.new("INITIATIVES_STATS_CACHE_EXPIRATION_TIME").to_i.minutes
    end
    if Decidim::Env.new("INITIATIVES_MAX_TIME_IN_VALIDATING_STATE").present?
      config.max_time_in_validating_state = Decidim::Env.new("INITIATIVES_MAX_TIME_IN_VALIDATING_STATE").to_i.days
    end
    print_enabled = Decidim::Env.new("INITIATIVES_PRINT_ENABLED", "auto").default_or_present_if_exists.to_s
    config.print_enabled = print_enabled.present? unless print_enabled == "auto"
    config.do_not_require_authorization = Decidim::Env.new("INITIATIVES_DO_NOT_REQUIRE_AUTHORIZATION").present?
  end
end

# Inform Decidim about the assets folder
Decidim.register_assets_path File.expand_path("app/packs", Rails.application.root)

Rails.application.config.i18n.available_locales = Decidim.available_locales
Rails.application.config.i18n.default_locale = Decidim.default_locale
