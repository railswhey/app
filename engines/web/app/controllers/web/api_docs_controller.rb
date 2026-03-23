# frozen_string_literal: true

class Web::APIDocsController < Web::BaseController
  # Public endpoint — no authentication needed

  SECTIONS = %w[index users task_lists task_items my_tasks search members invitations transfers].freeze

  def show
    @section = SECTIONS.include?(params[:section]) ? params[:section] : "index"

    respond_to do |format|
      format.html do
        @content = render_to_string(template: "api_docs/#{@section}", layout: false).html_safe
        render "api_docs/show", layout: "api_docs"
      end
      format.md do
        content = SECTIONS.map do |s|
          heading = s.tr("_", " ").split.map(&:capitalize).join(" ")
          "# #{heading}\n\n#{section_markdown(s)}"
        end.join("\n\n---\n\n")
        render plain: content, content_type: "text/markdown"
      end
    end
  end

  private

  def section_markdown(section)
    path = Web::Engine.root.join("app/views/web/api_docs/#{section}.html.md")
    return "*No documentation yet.*" unless File.exist?(path)
    ERB.new(File.read(path)).result(binding)
  end
end
