# frozen_string_literal: true

# A bunch of issues, all belonging to one Site
class Issueslist
  def initialize(site)
    @site = site
    @issues = []
  end

  def add(issue)
    @issues << issue
  end

  def empty
    @issues.clear
  end

  def locate_issue(number)
    @issues.find { |i| i.number == number }
  end

  def issue_numbers
    @issues.map(&:number)
  end

  def build_all
    @issues.each(&:build_one_issue)
  end

  def issues_page_template
    # Like a normal page but with no photo or header
    template_text(@site)
      .sub('<body>', '<body id="i">')
      .sub(%r{<header>.*?</header>}m, '')
      .sub(%r{<p id="coverphotoattribution">.*?</p>}, '')
      .sub('{version}', version)
  end

  def issues_page_ol
    # Generates the <ol> of issues for the issues page
    <<~ENDOFSTRING
      \n<ol id=\"issueslist\">
      #{@issues.reverse.map(&:issues_page_li).join("\n")}
      </ol>
    ENDOFSTRING
  end

  def make_issues_page(folder)
    list = <<~ENDOFSTRING
      <h2>#{headline(@site)}</h2>
      <p><a class="floaty tight" href="/index/">&nbsp;Index of all issues&nbsp;&gt;&nbsp;</a></p>
      #{issues_page_ol}
    ENDOFSTRING
    content = issues_page_template.sub('{article-or-table-of-contents}', list)
    dirname = File.join(folder, 'issues')
    ensure_dir(dirname)
    File.write(File.join(dirname, 'index.html'), content)
  end
end
