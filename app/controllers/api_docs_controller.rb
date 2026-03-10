# frozen_string_literal: true

class APIDocsController < ApplicationController
  # Public endpoint — no authentication needed
  # (authenticate_user! is called explicitly in controllers that need it)

  SECTIONS = %w[index users task_lists task_items my_tasks search members invitations transfers].freeze

  def show
    @section = SECTIONS.include?(params[:section]) ? params[:section] : "index"
    @content = render_to_string(template: "api_docs/#{@section}", layout: false).html_safe
    render "api_docs/show", layout: "api_docs"
  end

  def raw
    content = SECTIONS.map do |s|
      heading = s.tr("_", " ").split.map(&:capitalize).join(" ")
      "# #{heading}\n\n#{section_markdown(s)}"
    end.join("\n\n---\n\n")
    render plain: content, content_type: "text/markdown"
  end

  private

  def section_markdown(section)
    path = Rails.root.join("app/views/api_docs/#{section}.html.md")
    return "*No documentation yet.*" unless File.exist?(path)
    ERB.new(File.read(path)).result(binding)
  end
end
