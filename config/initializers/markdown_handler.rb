# frozen_string_literal: true

module MarkdownHandler
  RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap: true, tables: true),
    autolink: true, tables: true, fenced_code_blocks: true
  )

  def self.call(template, source)
    compiled = ERB.new(source).src
    <<~RUBY
      _md_source = begin
        #{compiled}
      end
      MarkdownHandler::RENDERER.render(_md_source).html_safe
    RUBY
  end
end

Rails.application.config.to_prepare do
  ActionView::Template.register_template_handler(:md, MarkdownHandler)
end
