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
    puts 'Installing.'
    check_all_folders
    copy_all_files
    puts 'Installation successful'
  end

  private

  COPY_TO_WEB_ROOT = %w[
    index.html
    favicon.ico
    robots.txt
    404.html
  ].freeze

  COPY_TO_IMG = %w[
    bclogo.png
    favicon16.png
    favicon32.png
    favicon96.ico
    favicon-apple-touch.png
  ].freeze

  COPY_TO_SOURCE = %w[
    bcstyle.css
    manifest.txt
    template.txt
  ]

  def check_exists_and_empty(folder)
    if Dir.exist?(folder)
      abort "ERROR: directory #{folder} is not empty" unless Dir.empty?(folder)
    else
      FileUtils.mkdir_p(folder)
    end
  end

  def check_all_folders
    [@folder_source, @folder_output, @folder_img].each do |f|
      check_exists_and_empty(f)
    end
  end

  def copy_one_file(filename, source, dest)
    f_in = Pathname(source).join(filename)
    abort "ERROR: file #{f_in} not found" unless File.file?(f_in)

    f_out = Pathname(dest).join(filename)
    abort "ERROR: file #{f_out} already exists" if File.exist?(f_out)

    FileUtils.cp(f_in, f_out)
  end

  def copy_all_files
    COPY_TO_WEB_ROOT.each do |f|
      copy_one_file(f, @folder_my_resources, @folder_output)
    end
    COPY_TO_IMG.each do |f|
      copy_one_file(f, @folder_my_resources, @folder_img)
    end
    COPY_TO_SOURCE.each do |f|
      copy_one_file(f, @folder_my_resources, @folder_source)
    end
  end
end
