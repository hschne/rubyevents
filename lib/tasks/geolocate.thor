require "bundler/setup"
require "dotenv/load"
require "yaml"
require "httparty"
require "parallel"
require_relative "../../config/environment"

class Geolocate < Thor
  desc "playlists", "Geolocate playlist entries based on location field"
  option :files, aliases: :f, type: :string, default: "data/**/playlists.yml", desc: "Glob pattern or file path for playlist files"
  option :overwrite, type: :boolean, default: false, desc: "Overwrite existing coordinates"
  def playlists
    api_key = ENV["GEOLOCATE_API_KEY"]
    if api_key.nil? || api_key.empty?
      puts "Error: GEOLOCATE_API_KEY environment variable not set"
      exit 1
    end

    files = Dir.glob(options[:files])
    if files.empty?
      puts "No files found matching pattern: #{options[:files]}"
      exit 1
    end

    Parallel.each(files, in_threads: 5) do |file_path|
      process_playlist_file(file_path, api_key, options[:overwrite])
    end
  end

  desc "events", "Geolocate events from the database based on location field"
  option :overwrite, type: :boolean, default: false, desc: "Overwrite existing coordinates"
  def events
    api_key = ENV["GEOLOCATE_API_KEY"]
    if api_key.nil? || api_key.empty?
      puts "Error: GEOLOCATE_API_KEY environment variable not set"
      exit 1
    end

    events_to_geocode = if options[:overwrite]
      Event.all
    else
      Event.where(lng: nil).or(Event.where(lat: nil))
    end

    if events_to_geocode.empty?
      puts "No events to geocode"
      return
    end

    Parallel.each(events_to_geocode, in_threads: 5) do |event|
      process_event(event, api_key, options[:overwrite])
    end
  end

  private

  def process_playlist_file(file_path, api_key, overwrite)
    data = YAML.load_file(file_path)

    unless data
      puts "⚠ Skipping #{file_path}, failed to parse YAML"
      return
    end

    modified = false

    data.each do |entry|
      next unless entry.is_a?(Hash)

      location = entry["location"]
      next if location.nil? || location.empty?
      next if entry["coordinates"] && !overwrite

      coordinates = geocode_location(location, api_key)

      if coordinates
        entry["coordinates"] = coordinates
        modified = true
        puts "✓ #{file_path}: #{entry["title"]} (#{location}) -> #{coordinates}"
      else
        puts "✗ #{file_path}: Failed to geocode #{entry["title"]} (#{location})"
      end
    end

    return unless modified

    File.write(file_path, YAML.dump(data))
  rescue => e
    puts "✗ Error processing #{file_path}: #{e.message}"
  end

  def process_event(event, api_key, overwrite)
    location = event.static_metadata&.location
    unless location.present?
      puts "⚠ Skipping #{event.name}: No location in metadata"
      return
    end

    if event.lng.present? && event.lat.present? && !overwrite
      puts "⚠ Skipping #{event.name}: Already has coordinates"
      return
    end

    coordinates = geocode_location(location, api_key)

    if coordinates
      lng, lat = coordinates.split(",").map(&:to_f)
      event.update(lng: lng, lat: lat)
      puts "✓ #{event.name} (#{location}) -> #{coordinates}"
    else
      puts "✗ Failed to geocode #{event.name} (#{location})"
    end
  rescue => e
    puts "✗ Error processing #{event.name}: #{e.message}"
  end

  def geocode_location(location, api_key)
    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/geocode/json",
      query: {address: location, key: api_key}
    )

    return nil unless response.success?
    return nil unless response["status"] == "OK"
    return nil if response["results"].empty?

    location_data = response["results"][0]["geometry"]["location"]
    "#{location_data["lng"]},#{location_data["lat"]}"
  rescue => e
    puts "    Error: #{e.message}"
    nil
  end
end
