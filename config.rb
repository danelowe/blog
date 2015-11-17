###
# Blog settings
###

# Time.zone = "UTC"

activate :blog do |blog|
  # This will add a prefix to all links, template references and source paths
  # blog.prefix = "blog"

  blog.permalink = "{title}.html"
  # Matcher for blog source files
  blog.sources = "posts/{year}-{month}-{day}-{title}.html"
  # blog.taglink = "tags/{tag}.html"
  blog.layout = 'article'
  # blog.summary_separator = /(READMORE)/
  # blog.summary_length = 250
  # blog.year_link = "{year}.html"
  # blog.month_link = "{year}/{month}.html"
  # blog.day_link = "{year}/{month}/{day}.html"
  # blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"

  # Enable pagination
  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/{num}"
end

activate :syntax
set :markdown_engine, :kramdown
set :haml, { ugly: true } #otherwise code blocks get auto-indented!

page "/feed.xml", layout: false

###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", layout: false
#
# With alternative layout
# page "/path/to/file.html", layout: :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
activate :livereload

activate :disqus do |d|
  # Disqus shotname, without '.disqus.com' on the end (default = nil)
  d.shortname = 'danelowe'
end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  require 'closure-compiler'
  activate :minify_javascript
  #set :js_compressor, ::Closure::Compiler.new(compilation_level: 'ADVANCED_OPTIMIZATIONS')
  set :js_compressor, ::Closure::Compiler.new

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"

  activate :favicon_maker, :icons => {
      'favicon_template.png' => [
          { icon: 'apple-touch-icon-152x152-precomposed.png' },
          { icon: 'apple-touch-icon-144x144-precomposed.png' },
          { icon: 'apple-touch-icon-120x120-precomposed.png' },
          { icon: 'apple-touch-icon-114x114-precomposed.png' },
          { icon: 'apple-touch-icon-76x76-precomposed.png' },
          { icon: 'apple-touch-icon-72x72-precomposed.png' },
          { icon: 'apple-touch-icon-60x60-precomposed.png' },
          { icon: 'apple-touch-icon-57x57-precomposed.png' },
          { icon: 'apple-touch-icon-precomposed.png', size: '57x57' },
          { icon: 'apple-touch-icon.png', size: '57x57' },
          { icon: 'favicon-196x196.png' },
          { icon: 'favicon-160x160.png' },
          { icon: 'favicon-96x96.png' },
          { icon: 'favicon-32x32.png' },
          { icon: 'favicon-16x16.png' },
          { icon: 'favicon.png', size: '16x16' },
          { icon: 'favicon.ico', size: '64x64,32x32,24x24,16x16' },
          { icon: 'mstile-144x144', format: 'png' },
      ]
  }

end
