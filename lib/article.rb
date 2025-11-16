# frozen_string_literal: true

# One article, having author and text, belonging to an issue
class Article
  attr_reader :grub, :title

  def initialize(site:, grub:, title:, issue:)
    @site = site
    @grub = grub
    @title = title
    @issue = issue
    @author = ''
    @issue.new_article(self)
    @issue.site.catalogue[slug] = @title
  end

  def slug
    "#{@issue.number}#{@grub}"
  end

  def write_html
    folder = @issue.site.config.get(:folder_output)
    dirname = File.join(folder, slug)
    ensure_dir(dirname)
    File.write(File.join(dirname, 'index.html'), make_page)
  end

  def author_c
    # html for contents page
    "&nbsp;<em>(#{@author})</em>" if @author && !@author.empty?
    # else nil
  end

  private

  def next_or_previous_link(article, is_next)
    return unless article

    arrow = is_next ? '&#x21e8;' : '&#x21e6;'
    "<tr><th>#{arrow}</th><td>"\
      "<a class=\"plain\" href=\"/#{article.slug}/\">#{article.title}</a>"\
      '</td></tr>'
  end

  def next_and_previous_links
    <<~ENDOFSTRING
      <hr>\n
      <table id=\"endlinks\">
      #{next_or_previous_link(@issue.next_article(self), true)}
      #{next_or_previous_link(@issue.previous_article(self), false)}
      </table>
    ENDOFSTRING
  end

  def contents_links
    <<~ENDOFSTRING
      <p>
      <a class=\"neat oneline\" href=\"/#{@issue.number}/\">Contents of this issue</a>
      <a class=\"neat oneline\" href=\"/index/\">Index of all issues</a>
      </p>
    ENDOFSTRING
  end

  def make_html_from_source(source_text)
    @author = source_text[0].chomp
    writing = source_text[1..]
    <<~ENDOFSTRING
      \n<article>\n
      <h2>#{@title}</h2>
      <h4>#{@author}</h4>
      #{Parser.new(lines: writing, slug: slug, site: @issue.site).to_html}
      </article>
      #{pdf_link(@site, slug)}
      #{next_and_previous_links}
      #{contents_links}
    ENDOFSTRING
  end

  def html
    folder = @site.config.get(:folder_source)
    filespec = File.join(folder, "#{slug}.txt")
    unless File.exist?(filespec)
      File.open(filespec, 'w') do |f|
        f.puts "\n.4 (Article in preparation)"
      end
    end
    source_text = File.readlines(filespec)
                      .map { |s| s.gsub(' & ', ' &amp; ') }
    make_html_from_source(source_text)
  end

  def make_page
    @issue
      .semi
      .clone
      .sub('<body>', '<body id="a">') # mark for "article" styling
      .sub('{headline}', headline(@site))
      .sub('{article-or-table-of-contents}', html)
      .sub('{links}', "<a href=\"/#{@issue.number}/\">Contents</a>")
      .gsub('-----', '<br>')
  end
end
