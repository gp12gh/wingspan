# frozen_string_literal: true

# Class for setting up folders etc
class Installer

  def initialize(site)
    @site = site
    @config = site.config
    @folder_source = @config.get(:folder_source)
    @folder_output = @config.get(:folder_output)
    @folder_img = Pathname(@folder_output).join('img')
    @folder_my_resources = Pathname(__dir__).join('..', 'resources')
  end

  def install
    puts 'Installing'
    check_all_folders
  end

  private

  COPY_TO_WEB_ROOT = %w[
    index.html
    favicon.ico
    robots.txt
    404.html    
  ]

  COPY_TO_IMG = %w[
    bclogo.png
    favicon16.png
    favicon32.png
    favicon96.ico
    favicon-apple-touch.png
  ]

  REQUIRED_FOLDERS = [
    @folder_source,
    @folder_output,
    @folder_img
  ]

  def check_exists_and_empty(folder)
    if Dir.exist?(folder)
      raise "Directory #{folder} is not empty" unless Dir.empty()
    else
      Dir.mkdir(folder)
    end
  end

  def check_all_folders
    REQUIRED_FOLDERS.each do |f|
      check_exists_and_empty(f)
    end
  end



end