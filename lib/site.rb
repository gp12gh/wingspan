# frozen_string_literal: true

# The whole website, has many issues and two indexes
class Site
  attr_reader :catalogue, :index_english, :index_latin, :config

  def initialize
    @issues = Issueslist.new(self)
    # List of index terms and, for each, a list of article slugs:
    @index_english = Hash.new { |h, k| h[k] = [] }
    @index_latin = Hash.new { |h, k| h[k] = [] }
    @catalogue = {} # list of article titles for use by the index builder
    @config = Configurator.new
    load_manifest
  end

  def listen
    folder = @config.get(:folder_source)
    puts "Watching #{folder} for changes... (Ctrl+C to stop)"
    listener = Listen.to(folder) do |changed, added, _removed|
      (changed + added).each { |f| refresh_file(f) }
    end
    listener.start
    sleep
  end

  private

  def one_manifest_line(str, current_issue)
    this_issue = current_issue
    if str =~ /^\d/
      this_issue = Issue.new(manifest_line: str, site: self)
      @issues.add(this_issue)
    elsif (md = /^\s+(\w+)\s*(.*)$/.match(str))
      raise "Manifest format error: no issue for article #{md[1]}" unless this_issue

      Article.new(site: self, grub: md[1], title: md[2], issue: this_issue)
    end
    this_issue
  end

  def load_manifest
    @issues.empty
    this_issue = nil
    File.foreach(@config.get(:filespec_manifest)) do |s|
      next if s[0] == '#'

      this_issue = one_manifest_line(s, this_issue)
    end
    this_issue.set_as_index # The last issue in the manifest is the index_page issue
    build_whole_site
  end

  def locate_article(slug)
    md = /^(\d+)(\w+)$/.match(slug)
    raise "Malformed slug: #{slug}" unless md

    issue = @issues.locate_issue(md[1])
    raise "Issue not found: #{md[1]}" unless issue

    article = issue.find_article(md[2])
    raise "Article not found: #{md[2]} in issue #{md[1]}" unless article

    article
  end

  def copy_css
    filename = @config.get(:filename_stylesheet)
    filespec_in = File.join(@config.get(:folder_source), filename)
    filespec_out = File.join(@config.get(:folder_output), filename)
    FileUtils.cp(filespec_in, filespec_out)
    puts "css #{Time.now.strftime('%H:%M')}"
  end

  def build_whole_site
    @issues.build_all
    make_issues_page
    Index.new(self, false).make_index_page
    Index.new(self, true).make_index_page
    copy_css
  end

  def make_issues_page
    @issues.make_issues_page(@config.get(:folder_output))
  end

  def refresh_file(filespec)
    slug = File.basename(filespec, '.*')
    puts slug
    case slug
    when 'bcstyle'
      copy_css
    when 'manifest'
      load_manifest # also rebuilds
    else
      locate_article(slug).write_html
    end
  end
end
