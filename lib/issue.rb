# frozen_string_literal: true

# One issue of the printed newsletter, containing many articles
class Issue
  attr_reader :number, :site, :hidden

  def initialize(manifest_line:, site:)
    @site = site
    parse_manifest_line(manifest_line)
    @articles = []
    @semi = nil # Cached copy of the semi-processed template
    @index_page = false # site root page
    @folder_out = @site.config.get(:folder_output)
  end

  def current_issue?
    @index_page
  end

  def parse_manifest_line(manifest_line)
    # 104 Spring 2023 #D9E4F9 Muslin Moth by John Kelf # Sample new format
    md = /^([0-9-]+)\s+([^#]+)(#\h+)\s+(.*)$/.match(manifest_line)
    if md
      do_match_data(md)
    else
      raise "Bad issue in manifest: #{manifest_line}" unless md
    end
  end

  def do_match_data(md)
    @hidden = md[1].start_with?('-') # future issue, generated but not yet linked
    @number = @hidden ? md[1][1..] : md[1]
    @date = md[2].strip
    @color = md[3]
    @photo = md[4]
  end

  def new_article(art)
    @articles << art
    @site.catalogue[art.slug] = art.title
  end

  def set_as_index
    @index_page = true
  end

  def build_one_issue
    # In order to read authors, must do articles before contents.
    @articles.each(&:write_html)
    write_contents_page
  end

  def semi
    # Half-built template, with issue-specific data but not article-specific data. Cached for efficiency.
    @semi ||= make_semi
  end

  def previous_article(article)
    idx = @articles.index(article)
    idx&.positive? ? @articles[idx - 1] : nil
  end

  def next_article(article)
    idx = @articles.index(article)
    idx && idx < @articles.size - 1 ? @articles[idx + 1] : nil
  end

  def issues_page_li
    # List item for site Issues page
    <<~ENDOFSTRING
      <a href=\"/#{@number}/\" class=\"plain\">
      <li style=\"background-color:#{@color}\">
      <img src=\"/img/#{@number}.webp\">Issue&nbsp;#{@number}&nbsp;&ndash;
        #{@date.sub(' ', '&nbsp;')}
      </li>
      </a>
    ENDOFSTRING
  end

  def find_article(grb)
    @articles.find { |a| a.grub == grb }
  end

  private

  def article_links
    @articles.map do |a|
      "<li>\n  <a href=\"/#{a.slug}/\">#{a.title}#{a.author_c}</a>\n</li>"
    end.join("\n")
  end

  def toc
    <<~ENDOFSTRING
      <h4>Contents</h4>
      <ol class=\"toc\">
      #{article_links}
      </ol>
      #{pdf_link(@site, @number)}
      <p><a class=\"plain petite\" href=\"/index/\">Index to all issues</a></p>
    ENDOFSTRING
  end

  def make_semi
    # part-processed template, re-used in all pages
    template_text(@site)
      .sub('{cover-photo}', "alt=\"#{@photo}\" src=\"/img/#{@number}.webp\"")
      .sub('{cover-photo-attribution}', @photo)
      .sub('{version}', version)
      .sub('{issue-number-season-year}', "Issue #{@number}, #{@date}")
      .sub('transparent', @color)
  end

  def write_contents_page
    homelink = current_issue? ? '' : '<a class="buttony" href="/">&lt;&nbsp;Current issue</a>'
    page = semi
           .sub('{headline}', headline(@site))
           .sub('<body>', '<body id="c">')
           .sub('{article-or-table-of-contents}', toc)
           .sub('{links}', "#{homelink}<a class=\"buttony\" href=\"/issues/\">Past&nbsp;issues</a>") 
    dirname = File.join(@folder_out, @number)
    ensure_dir(dirname)
    File.write(File.join(dirname, 'index.html'), page)
    File.write(File.join(@folder_out, 'index.html'), page) if current_issue?
  end
end
