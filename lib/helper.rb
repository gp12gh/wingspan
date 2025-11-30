# frozen_string_literal: true

# Class to assist the Parser
class Helper
  def initialize(site, slug)
    @slug = slug
    @index_english = site.index_english
    @index_latin = site.index_latin
  end

  def parse_one_line(str)
    # Splits line of MyML into "control" (eg '.ol'), "styling" (class or id) and the actual text,
    # any of which may be nil.
    return [nil, nil, link_nbsp_index(str)] unless str[0] == '.' # text only
    return [str, nil, nil] if str =~ /^\.[a-z0-9]*$/ # control only

    parts = str.split(/\s+/, 2) # [control+styling, text]
    md = /^(\.[a-z0-9]+)(.*)$/.match(parts[0])
    # raise "Bad control[a] line in #{@slug}: #{str} - #{md.inspect}" unless md && md[1] && md[2]

    styling = md[2].empty? ? nil : md[2].strip
    [md[1], styling, link_nbsp_index(parts[1])] # control, styling, text
  end

  def tidyup(txt)
    bold_and_italic(txt)
    txt.gsub!(UNDERSCORE_BLANK, '_blank')
    # right-align numeric data cells
    txt.gsub!(%r{<td>([-0-9. ,(£)]+)</td>}, '<td class="r">\1</td>')
    txt
  end

  def alt_caption(str)
    s = str.strip
    if s[0] == '-' # no caption wanted
      [s[1..], '']
    else
      [s, "<figcaption>#{s}</figcaption>"]
    end
  end

  private

  UNDERSCORE_BLANK = 'sjchdhgffrwsusuehdmdf' # Arbitrary "magic" constant
  DOUBLE_STAR      = 'mndjdhsyebngfsypsjenf'

  INDEX_REGEX_I     = /^(.*?)(I--)(.*?)(--I)(.*)$/.freeze
  INDEX_REGEX_J     = /^(.*?)(J--)(.*?)(--J)(.*)$/.freeze
  INDEX_LATIN_REGEX = /_[A-Z][a-z]+ [a-z]+_/.freeze

  def bold_and_italic(txt)
    # Replace *bold* and _italic_ with HTML tags
    txt.gsub!('**', DOUBLE_STAR)
    txt.gsub!(/(\*(.*?)\*|_(.*?)_)/) do |match|
      if match.start_with?('*')
        "<strong>#{::Regexp.last_match(2)}</strong>" # in earlier versions, referenced as $2
      else
        "<em>#{::Regexp.last_match(3)}</em>"
      end
    end
    txt.gsub!(DOUBLE_STAR, '*')
  end

  def indexify(str)
    # Removes index markers, inserts index items into site indexes
    [INDEX_REGEX_I, INDEX_REGEX_J].each do |regex|
      while (md = regex.match(str))
        term = regex == INDEX_REGEX_I ? md[3] : nil # omit term for J-type markers
        key = capitalize1(md[3])
        @index_english[key] << @slug
        str = "#{md[1]}#{term}#{md[5]}"
        # str = "#{md[1]}◄#{md[3]}►#{md[5]}" # For review only
      end
    end
    str&.scan(INDEX_LATIN_REGEX) { |m| @index_latin[m[1..-2]] << @slug }
  end

  def link_nbsp_index(txt)
    # linkify, indexify and replace backticks.
    return unless txt

    s = txt
        .dup
        .strip
        .gsub(/`/, '&nbsp;')
        .gsub(/\[\[.*?\]\]/) { |match| linkify(match) }
    indexify(s)
  end

  def linkify(str)
    # Convert [[url label]] or [[.class url label]] to links
    components = str[2..-3].split(' ')
    if components[0][0] == '.' # class present
      cls = " class=\"#{components[0][1..]}\""
      components.shift
    end
    url = components[0]
    txt = components[1..].join(' ')
    tgt = url.start_with?('http') ? " target=\"#{UNDERSCORE_BLANK}\"" : ''
    "<a#{cls}#{tgt} href=\"#{url}\">#{txt}</a>"
  end
end
