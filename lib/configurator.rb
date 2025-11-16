# frozen_string_literal: true

# Class to read and store configuration data
class Configurator
  def initialize
    @store = {}
    load
  end

  def get(key)
    @store[key] || (raise "Config key not found: #{key}")
  end

  private

  def load
    config_filespec = Pathname(__dir__).join('..', 'config.txt')
    raise "Config file not found: #{config_filespec}" unless File.exist?(config_filespec)

    fill(config_filespec)
    check
  end

  def fill(filespec)
    File.readlines(filespec).each do |line|
      next if line.strip.empty? || line.start_with?('#')

      key, value = line.chomp.split('=', 2)
      raise "Bad config line: #{line}" unless key && value

      @store[key.strip.intern] = value.strip
    end
  end

  # rubocop:disable Metrics/MethodLength
  def required_keys
    %i[
      folder_source
      folder_output
      filespec_template
      filespec_manifest
      filename_stylesheet
      title_text
      page_headline
      pdf_prefix
      contact_email
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def check
    missing_keys = required_keys.reject { |k| @store.key?(k) }
    return if missing_keys.empty?

    raise "Config file is missing required keys: #{missing_keys.join(', ')}"
  end
end
