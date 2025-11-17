# frozen_string_literal: true

# Class for reading MyML source text and writing out HTML
class Parser
  def initialize(lines:, slug:, site:)
    @lines = lines
    @slug = slug
    @helper = Helper.new(site, slug)
    @current_line = 0
  end

  def to_html
    state = :p # Assume paragraph unless indicated otherwise
    @lines.map.with_index do |line, i|
      @current_line = i + 2 # For error messages (first line is author)
      control, styling, text = @helper.parse_one_line(line.chomp)
      attributes = get_attributes(styling)
      answer = process_line(control, text, attributes, state)
      state = answer[:new_state] if answer[:new_state]
      @helper.tidyup(answer[:html].dup)
    end.join("\n")
  end

  private

  def process_line(control, text, attributes, current_state)
    if control
      process_control_code(control, text, attributes, current_state)
    else
      process_stateful_content(text, attributes, current_state)
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
  # IMO, making this Rubocop-compliant (eg with a dispatch table) would make it less readable.
  def process_control_code(control, text, attributes, current_state)
    case control
    when '.d'  then { html: "<div#{attributes}>", new_state: :p }
    when '.dx' then { html: '</div>', new_state: :p }
    when '.h'  then { html: "  <tr#{attributes}><th>#{text.gsub(/\t/, '</th><th>')}</th></tr>" }
    when '.i'  then { html: image_element(text.strip, attributes) }
    when '.ol' then { html: "<ol#{attributes}>", new_state: :ol }
    when '.p'  then { html: "<p#{attributes}>#{text}</p>", new_state: :p }
    when '.t'  then { html: "<table#{attributes}>#{caption_text(text)}", new_state: :table }
    when '.ul' then { html: "<ul#{attributes}>", new_state: :ul }
    when '.'   then { html: "</#{current_state}>", new_state: :p }
    when /\.[1-6]/ then { html: "<h#{control[1]}#{attributes}>#{text}</h#{control[1]}>" }
    else
      raise "Cannot parse line #{@current_line}: #{control}"
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

  def process_stateful_content(text, attributes, state)
    # handles plain text lines, depending on current state
    html = case state
           when :p then "<p>#{text}</p>"
           when :ol, :ul then "  <li#{attributes}>#{text}</li>"
           when :table then "  <tr#{attributes}><td>#{text.gsub(/\t/, '</td><td>')}</td></tr>"
           end
    { html: html }
  end

  def image_element(str, attributes)
    md = %r{^([-a-z0-9◄►/.]+)\s(.*)$}.match(str)
    raise "Bad or incomplete image marker at line #{@current_line} [#{str}]" unless md

    alt, caption = @helper.alt_caption(md[2])
    filename = "/img/#{@slug}-#{md[1]}"
    filename << '.webp' unless filename.include?('.')
    <<~ENDOFSTRING
      <figure#{attributes}>
        <img src="#{filename}" alt="#{alt}">
        #{caption}
      </figure>
    ENDOFSTRING
  end

  def caption_text(str)
    str && str[0] ? "\n  <caption>#{str}</caption>" : ''
  end

  def get_attributes(styling)
    return '' if styling.nil?

    css_class = styling[1..].gsub('.', ' ') # can have two or more classes
    return " class=\"#{css_class}\"" if styling[0] == '.'
    return " id=\"#{styling[1..]}\"" if styling[0] == '#'

    raise "unexpected qualifier at line #{@current_line} [#{styling}]"
  end
end
