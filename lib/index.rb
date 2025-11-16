# frozen_string_literal: true

# Utility class to generate index pages for the Site
class Index
  def initialize(site, latin)
    @site = site
    @latin = latin
  end

  def index_page_template
    # Like a normal page but with no photo or header
    template_text(@site)
      .sub('<body>', '<body id="x">')
      .sub(%r{<header>.*?</header>}m, '')
      .sub(%r{<p id="coverphotoattribution">.*?</p>}, '')
      .sub('{version}', version)
  end

  def index_page_text(titl, href, link)
    <<~ENDOFSTRING
      <h2>#{headline(@site)}</h2>
      <p class="floaty righty tight smaller">
        <a class="floaty tight" href="/">Home</a><br>
        <a class="floaty tight" href="#{href}">#{link}</a>
      </p>
      <h3 class="underlined">#{titl}</h3>
    ENDOFSTRING
  end

  def index_page_listing
    # Generates the index listing (and empty <dl>) part of one index page
    titl = @latin ? 'Index of Latin names' : 'Index'
    href = @latin ? '/index/' : '/indexlatin/'
    link = @latin ? 'English index' : 'Index of Latin names'
    index_page_text(titl, href, link) +
      index_entries_dl
  end

  def index_list(slugs)
    # Generates the <ol> of page links for one index item
    lines = ['<ol>']
    slugs.reverse_each do |slug| # most recent first
      title = @site.catalogue[slug]
      lines << "<li><span class=\"issuenumber\">#{slug[0, 3]}</span> "\
        "<a href=\"/#{slug}/\">#{title}</a></li>"
    end
    lines << '</ol>'
    lines.join("\n")
  end

  def index_item(key, idx, previous_letter)
    # Generates one <dt> and <dd> for an index
    # Note: idx is already either the English or Latin index hash
    lines = []
    slugs = idx[key].uniq.sort
    unique_id = key.downcase.gsub(/\W/, '') # only word characters allowed
    gap = key[0].upcase == previous_letter ? '' : ' class="gappy"'
    lines << "<dt#{gap}><a href=\"#\" class=\"plain\" onclick=\"showhide('#{unique_id}'); "\
      "return false;\">#{key}</a></dt>"
    lines << "<dd id=\"#{unique_id}\" style=\"display:none;\">"
    lines << index_list(slugs)
    lines << '</dd>'
    lines.join("\n")
  end

  def index_entries_dl
    # Generates all the entries for one <dl> index
    lines = ['<dl>']
    idx = @latin ? @site.index_latin : @site.index_english
    previous_letter = 'A'
    idx.keys.sort { |a, b| a.upcase <=> b.upcase }.each do |k|
      lines << index_item(k, idx, previous_letter)
      previous_letter = k[0].upcase
    end
    lines << '</dl>'
    lines.join("\n")
  end

  def make_index_page
    # Generates one entire index page (English or Latin)
    content = index_page_template.sub('{article-or-table-of-contents}', index_page_listing)
    folder = @site.config.get(:folder_output)
    dirname = File.join(folder, @latin ? 'indexlatin' : 'index')
    ensure_dir(dirname)
    File.write(File.join(dirname, 'index.html'), content)
  end
end
