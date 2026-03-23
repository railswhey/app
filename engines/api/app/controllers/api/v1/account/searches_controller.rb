# frozen_string_literal: true

class API::V1::Account::SearchesController < API::V1::BaseController
  before_action :authenticate_user!

  def show
    @query = params[:q].to_s.strip
    @results = current.workspace.search(@query)

    render :show
  end
end
