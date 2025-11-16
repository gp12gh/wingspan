# frozen_string_literal: true

require 'fileutils'
require 'listen'
require 'pathname'

# === Utility Methods === #

def ensure_dir(path)
  Dir.mkdir(path) unless Dir.exist?(path)
end

def capitalize1(str)
  # Capitalizes first letter only (cf Ruby's capitalize)
  letters = str.split('')
  letters.first.upcase! unless str == 'iRecord' # special exception
  letters.join
end

def version
  Time.now.strftime('%Y-%m-%d')
end

def template_text(site)
  filespec = site.config.get(:filespec_template)
  title_text = site.config.get(:title_text)
  contact_email = site.config.get(:contact_email)
  File.read(filespec)
      .sub('{title}', title_text)
      .gsub('{contact_email}', contact_email)
end

def headline(site)
  site.config.get(:page_headline)
end

def file_size_text(filespec)
  size_b = File.size(filespec)
  if size_b < 1_048_576
    "#{(size_b / 1024.0).to_i} KB"
  else
    format('%.1f MB', size_b / 1_048_576.0)
  end
end

def pdf_link_text(info)
  "\n<p>
  <a class=\"download\" href=\"/#{info[:filename]}\">
  Download #{info[:txt]} as PDF (#{file_size_text(info[:filespec])})</a>
  </p>"
end

def pdf_info(site, slug)
  prefix = site.config.get(:pdf_prefix)
  filename = "#{prefix}#{slug}.pdf"
  folder = site.config.get(:folder_output)
  filespec = File.join(folder, filename)
  {
    filename: filename,
    filespec: filespec,
    exists: File.file?(filespec),
    txt: /^\d+$/ =~ slug ? "Issue #{slug}" : 'this article'
  }
end

def pdf_link(site, slug)
  info = pdf_info(site, slug)
  if info[:exists]
    pdf_link_text(info)
  else
    ''
  end
end
