# frozen_string_literal: true

class Web::Account::SearchesController < Web::BaseController
  before_action :authenticate_user!

  def show
    @query = params[:q].to_s.strip

    @results = current.workspace.search(@query)
  end
end
